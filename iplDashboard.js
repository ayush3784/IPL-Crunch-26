/**
 * iplDashboard.js
 * LWC Controller for IPL Crunch '26 Dashboard
 * Author: Ayush Vats | MIET Meerut
 */
import { LightningElement, track, wire } from 'lwc';
import getTossAnalysis       from '@salesforce/apex/IPLDashboardController.getTossAnalysis';
import getPhaseAnalysis      from '@salesforce/apex/IPLDashboardController.getPhaseAnalysis';
import getTopBatters         from '@salesforce/apex/IPLDashboardController.getTopBatters';
import getTopBowlers         from '@salesforce/apex/IPLDashboardController.getTopBowlers';
import getVenueChaseAnalysis from '@salesforce/apex/IPLDashboardController.getVenueChaseAnalysis';

export default class IplDashboard extends LightningElement {

    // ── State ────────────────────────────────────────────────
    @track activeTab     = 'toss';
    @track isLoading     = false;

    // Toss
    @track totalMatches  = 0;
    @track tossWonPct    = 0;
    @track batWonPct     = 0;
    @track fieldWonPct   = 0;
    @track tossSeasonData = [];

    // Phase
    @track phaseData     = [];

    // Performers
    @track topBatters    = [];
    @track topBowlers    = [];

    // Venue
    @track venueData     = [];

    // ── Tab visibility ───────────────────────────────────────
    get showToss()       { return this.activeTab === 'toss'; }
    get showPhase()      { return this.activeTab === 'phase'; }
    get showPerformers() { return this.activeTab === 'performers'; }
    get showVenue()      { return this.activeTab === 'venue'; }

    get tab1Class() { return this.tabClass('toss'); }
    get tab2Class() { return this.tabClass('phase'); }
    get tab3Class() { return this.tabClass('performers'); }
    get tab4Class() { return this.tabClass('venue'); }

    tabClass(name) {
        return `tab-btn ${this.activeTab === name ? 'tab-active' : ''}`;
    }

    // ── Lifecycle ────────────────────────────────────────────
    connectedCallback() {
        this.loadTossData();
        this.loadPhaseData();
        this.loadPerformers();
        this.loadVenueData();
    }

    // ── Tab switch ───────────────────────────────────────────
    switchTab(event) {
        this.activeTab = event.target.dataset.tab;
    }

    // ── Data loaders ─────────────────────────────────────────
    loadTossData() {
        getTossAnalysis()
            .then(data => {
                this.totalMatches = data.totalMatches;
                this.tossWonPct   = data.tossWonPct;
                this.batWonPct    = data.batWonPct;
                this.fieldWonPct  = data.fieldWonPct;
                this.tossSeasonData = (data.seasonData || []).map(s => ({
                    ...s,
                    barStyle: this.barStyle(s.winPct, 100,
                        s.winPct >= 50 ? '#f4c430' : '#ff4136')
                }));
            })
            .catch(err => console.error('Toss data error', err));
    }

    loadPhaseData() {
        getPhaseAnalysis()
            .then(data => {
                const maxRuns = Math.max(...data.map(p => p.avgRunsPer));
                const icons   = { 'Powerplay': '⚡', 'Middle': '🎯', 'Death': '🔥' };
                const classes = { 'Powerplay': 'insight-card powerplay-card',
                                  'Middle':    'insight-card middle-card',
                                  'Death':     'insight-card death-card highlight-card' };
                this.phaseData = data.map(p => ({
                    ...p,
                    icon:          icons[p.phase] || '📊',
                    cardClass:     classes[p.phase] || 'insight-card',
                    barHeightStyle: `height:${(p.avgRunsPer / maxRuns * 200).toFixed(0)}px;background:${
                        p.phase === 'Death' ? '#f4c430' :
                        p.phase === 'Powerplay' ? '#2ecc40' : '#0074d9'}`
                }));
            })
            .catch(err => console.error('Phase data error', err));
    }

    loadPerformers() {
        getTopBatters()
            .then(data => {
                this.topBatters = data.map((b, i) => ({ ...b, rank: i + 1 }));
            })
            .catch(err => console.error('Batter data error', err));

        getTopBowlers()
            .then(data => {
                this.topBowlers = data.map((b, i) => ({ ...b, rank: i + 1 }));
            })
            .catch(err => console.error('Bowler data error', err));
    }

    loadVenueData() {
        getVenueChaseAnalysis()
            .then(data => {
                this.venueData = data.map(v => ({
                    ...v,
                    venueName: v.venue.length > 30
                               ? v.venue.substring(0, 28) + '…'
                               : v.venue,
                    barStyle: this.barStyle(
                        v.chaseWinPct, 100,
                        v.chaseWinPct >= 55 ? '#2ecc40' :
                        v.chaseWinPct <= 45 ? '#ff4136' : '#f4c430'
                    )
                }));
            })
            .catch(err => console.error('Venue data error', err));
    }

    // ── Helpers ──────────────────────────────────────────────
    barStyle(value, max, color) {
        const pct = Math.min((value / max) * 100, 100).toFixed(1);
        return `width:${pct}%;background:${color};`;
    }
}
