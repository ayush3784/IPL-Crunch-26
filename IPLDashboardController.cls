/**
 * IPLDashboardController.cls
 * Apex Controller for IPL Crunch '26 LWC Dashboard
 * Author: Ayush Vats | MIET Meerut
 *
 * All 4 analyses backed by SOQL:
 *   1. Toss Win → Match Win rate
 *   2. Phase-wise run production (Powerplay / Middle / Death)
 *   3. Top batters & bowlers (consistency-adjusted)
 *   4. Venue-wise chasing win % (surprise insight)
 */
public with sharing class IPLDashboardController {

    // ─────────────────────────────────────────────────────────
    // ANALYSIS 1: Toss Win Rate
    // ─────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getTossAnalysis() {
        Integer totalMatches = 0;
        Integer tossWonMatch = 0;
        Integer batFirst     = 0;
        Integer fieldFirst   = 0;
        Integer batWon       = 0;
        Integer fieldWon     = 0;

        List<Match__c> matches = [
            SELECT Toss_Winner__c, Toss_Decision__c, Winner__c
            FROM Match__c
            WHERE Winner__c != NULL
            AND Toss_Winner__c != NULL
        ];

        totalMatches = matches.size();
        for (Match__c m : matches) {
            if (m.Toss_Winner__c == m.Winner__c) tossWonMatch++;
            if (m.Toss_Decision__c == 'bat') {
                batFirst++;
                if (m.Toss_Winner__c == m.Winner__c) batWon++;
            } else {
                fieldFirst++;
                if (m.Toss_Winner__c == m.Winner__c) fieldWon++;
            }
        }

        // Season-wise breakdown
        List<AggregateResult> seasonData = [
            SELECT Season__c season, 
                   COUNT(Id) total,
                   SUM(CASE WHEN Toss_Winner__c = Winner__c THEN 1 ELSE 0 END) tossWins
            FROM Match__c
            WHERE Winner__c != NULL
            GROUP BY Season__c
            ORDER BY Season__c ASC
        ];

        List<Map<String, Object>> seasonList = new List<Map<String, Object>>();
        for (AggregateResult ar : seasonData) {
            Integer total    = (Integer) ar.get('total');
            Integer tossWins = Integer.valueOf(ar.get('tossWins'));
            seasonList.add(new Map<String, Object>{
                'season'  => ar.get('season'),
                'winPct'  => total > 0 ? (tossWins * 100.0 / total).setScale(1) : 0
            });
        }

        return new Map<String, Object>{
            'totalMatches'   => totalMatches,
            'tossWonPct'     => totalMatches > 0
                                ? (tossWonMatch * 100.0 / totalMatches).setScale(1) : 0,
            'batWonPct'      => batFirst > 0
                                ? (batWon * 100.0 / batFirst).setScale(1) : 0,
            'fieldWonPct'    => fieldFirst > 0
                                ? (fieldWon * 100.0 / fieldFirst).setScale(1) : 0,
            'seasonData'     => seasonList
        };
    }

    // ─────────────────────────────────────────────────────────
    // ANALYSIS 2: Phase Impact (Powerplay / Middle / Death)
    // ─────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPhaseAnalysis() {
        // Group deliveries by phase, aggregate runs
        List<AggregateResult> phaseData = [
            SELECT Phase__c phase,
                   SUM(Total_Runs__c) totalRuns,
                   COUNT(Id) deliveries,
                   COUNT(DISTINCT Match__c) matches
            FROM Delivery__c
            WHERE Phase__c != NULL
            GROUP BY Phase__c
            ORDER BY Phase__c ASC
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (AggregateResult ar : phaseData) {
            Decimal totalRuns   = (Decimal) ar.get('totalRuns');
            Integer matchCount  = Integer.valueOf(ar.get('matches'));
            result.add(new Map<String, Object>{
                'phase'       => ar.get('phase'),
                'avgRunsPer'  => matchCount > 0
                                 ? (totalRuns / matchCount).setScale(1) : 0,
                'totalRuns'   => totalRuns
            });
        }
        return result;
    }

    // ─────────────────────────────────────────────────────────
    // ANALYSIS 3: Top Batters (Consistency Score)
    // ─────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTopBatters() {
        List<AggregateResult> batterData = [
            SELECT Batsman__c batter,
                   SUM(Batsman_Runs__c) totalRuns,
                   COUNT(Id) balls,
                   COUNT(DISTINCT Match__c) innings
            FROM Delivery__c
            WHERE Batsman__c != NULL
            GROUP BY Batsman__c
            HAVING COUNT(Id) >= 200 AND COUNT(DISTINCT Match__c) >= 10
            ORDER BY SUM(Batsman_Runs__c) DESC
            LIMIT 20
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (AggregateResult ar : batterData) {
            Decimal totalRuns = (Decimal) ar.get('totalRuns');
            Integer balls     = Integer.valueOf(ar.get('balls'));
            Integer innings   = Integer.valueOf(ar.get('innings'));
            Decimal sr        = balls > 0 ? (totalRuns / balls * 100).setScale(1) : 0;
            Decimal avg       = innings > 0 ? (totalRuns / innings).setScale(1) : 0;
            Decimal score     = (sr * avg > 0)
                                ? Decimal.valueOf(Math.sqrt((sr * avg).doubleValue())).setScale(1)
                                : 0;
            result.add(new Map<String, Object>{
                'batter'           => ar.get('batter'),
                'totalRuns'        => totalRuns,
                'strikeRate'       => sr,
                'avgPerInnings'    => avg,
                'consistencyScore' => score
            });
        }

        // Sort by consistency score descending
        result.sort(new ConsistencyComparator());
        return result.size() > 10 ? result.subList(0, 10) : result;
    }

    // ─────────────────────────────────────────────────────────
    // ANALYSIS 3b: Top Bowlers
    // ─────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTopBowlers() {
        List<AggregateResult> bowlerData = [
            SELECT Bowler__c bowler,
                   COUNT(Id) balls,
                   SUM(Total_Runs__c) runsConceded,
                   SUM(CASE WHEN Is_Wicket__c = TRUE AND Dismissal_Kind__c != 'run out'
                            THEN 1 ELSE 0 END) wickets,
                   COUNT(DISTINCT Match__c) matches
            FROM Delivery__c
            WHERE Bowler__c != NULL
            GROUP BY Bowler__c
            HAVING COUNT(Id) >= 240 AND COUNT(DISTINCT Match__c) >= 10
            ORDER BY SUM(CASE WHEN Is_Wicket__c = TRUE
                              AND Dismissal_Kind__c != 'run out' THEN 1 ELSE 0 END) DESC
            LIMIT 10
        ];

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (AggregateResult ar : bowlerData) {
            Integer balls         = Integer.valueOf(ar.get('balls'));
            Decimal runsConceded  = (Decimal) ar.get('runsConceded');
            Integer wickets       = Integer.valueOf(ar.get('wickets'));
            Decimal economy       = balls > 0 ? (runsConceded / balls * 6).setScale(2) : 0;
            result.add(new Map<String, Object>{
                'bowler'      => ar.get('bowler'),
                'wickets'     => wickets,
                'economy'     => economy,
                'matches'     => ar.get('matches')
            });
        }
        return result;
    }

    // ─────────────────────────────────────────────────────────
    // ANALYSIS 4: Venue Chasing Win % (Surprise Insight)
    // ─────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getVenueChaseAnalysis() {
        List<Match__c> matches = [
            SELECT Venue__c, Toss_Winner__c, Toss_Decision__c,
                   Team1__c, Team2__c, Winner__c
            FROM Match__c
            WHERE Winner__c != NULL
            AND Venue__c != NULL
        ];

        Map<String, Integer> venueTotal = new Map<String, Integer>();
        Map<String, Integer> venueChaseWin = new Map<String, Integer>();

        for (Match__c m : matches) {
            String chasingTeam = (m.Toss_Decision__c == 'field')
                ? m.Toss_Winner__c
                : (m.Toss_Winner__c == m.Team1__c ? m.Team2__c : m.Team1__c);

            String v = m.Venue__c;
            if (!venueTotal.containsKey(v)) {
                venueTotal.put(v, 0);
                venueChaseWin.put(v, 0);
            }
            venueTotal.put(v, venueTotal.get(v) + 1);
            if (chasingTeam == m.Winner__c) {
                venueChaseWin.put(v, venueChaseWin.get(v) + 1);
            }
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (String venue : venueTotal.keySet()) {
            Integer total = venueTotal.get(venue);
            if (total >= 10) {
                Integer cWins = venueChaseWin.get(venue);
                result.add(new Map<String, Object>{
                    'venue'       => venue,
                    'total'       => total,
                    'chaseWinPct' => (cWins * 100.0 / total).setScale(1)
                });
            }
        }

        result.sort(new VenueChaseComparator());
        return result.size() > 12 ? result.subList(0, 12) : result;
    }

    // ─────────────────────────────────────────────────────────
    // Helper Comparators
    // ─────────────────────────────────────────────────────────
    private class ConsistencyComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Decimal scoreA = (Decimal) a.get('consistencyScore');
            Decimal scoreB = (Decimal) b.get('consistencyScore');
            return scoreB.compareTo(scoreA); // descending
        }
    }

    private class VenueChaseComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Decimal pctA = (Decimal) a.get('chaseWinPct');
            Decimal pctB = (Decimal) b.get('chaseWinPct');
            return pctB.compareTo(pctA); // descending
        }
    }
}
