🏏 IPL Crunch '26 — Salesforce Edition
Analytics Dashboard built on Salesforce Platform

Submission for Wooble IPL CRUNCH '26 | By Ayush Vats | MIET Meerut


🚀 Why Salesforce?
Most submissions will use Python or Excel. This project uses the full Salesforce stack — Custom Objects, Apex, SOQL, and LWC — to prove that enterprise platforms can power sports analytics just as effectively as traditional data tools.

🏗️ Architecture
CSV Data (Cricsheet.org)
        │
        ▼
Salesforce Custom Objects
   ├── Match__c         ← Match-level data + formula fields
   └── Delivery__c      ← Ball-by-ball data + Phase__c formula
        │
        ▼
Apex Controller (IPLDashboardController.cls)
   ├── getTossAnalysis()       ← Analysis 1
   ├── getPhaseAnalysis()      ← Analysis 2
   ├── getTopBatters()         ← Analysis 3a
   ├── getTopBowlers()         ← Analysis 3b
   └── getVenueChaseAnalysis() ← Analysis 4 (Surprise)
        │
        ▼
LWC Dashboard (iplDashboard)
   ├── 4 interactive tabs
   ├── Dark cricket theme
   └── Responsive bar charts + tables

📁 Repo Structure
ipl-sf-crunch-26/
├── sfdx-project.json
├── soql_queries.sql                          ← All SOQL queries (runnable in Dev Console)
├── screenshots/                              ← Dashboard screenshots
└── force-app/main/default/
    ├── objects/
    │   ├── Match__c/Match__c.object-meta.xml
    │   └── Delivery__c/Delivery__c.object-meta.xml
    ├── classes/
    │   ├── IPLDashboardController.cls
    │   └── IPLDashboardController.cls-meta.xml
    └── lwc/iplDashboard/
        ├── iplDashboard.html
        ├── iplDashboard.js
        ├── iplDashboard.css
        └── iplDashboard.js-meta.xml

⚙️ Setup Instructions
Prerequisites

Salesforce Developer Edition org (free at developer.salesforce.com)
Salesforce CLI (sf or sfdx)
VS Code + Salesforce Extension Pack

Step 1: Clone & Authenticate
bashgit clone https://github.com/ayush3784/ipl-sf-crunch-26
cd ipl-sf-crunch-26
sf org login web --alias ipl-org
Step 2: Deploy to Org
bashsf project deploy start --target-org ipl-org
Step 3: Load Data

Download matches.csv and deliveries.csv from Cricsheet.org
In Salesforce: Setup → Data Import Wizard
Import matches.csv → Match__c object
Import deliveries.csv → Delivery__c object (map match_id → Match__c lookup)

Step 4: Add Dashboard to App

Go to App Builder in Setup
Create new Lightning App Page
Drag IPL Dashboard component onto the page
Activate & view!


📊 Four Analyses
🎲 Analysis 1 — The Toss Myth
SOQL-powered toss win rate calculation across all seasons.
Finding: Toss winner wins only ~51% of matches — statistically a coin flip.
⚡ Analysis 2 — Phase Impact
Aggregate runs per phase per match using formula field Phase__c.
Finding: Death overs (16–20) show the biggest gap between winners and losers.
🏆 Analysis 3 — True Top Performers
Consistency Score = √(Avg per Innings × Strike Rate) via Apex computation.
Finding: Consistency rankings differ significantly from raw runs/wickets leaders.
😲 Analysis 4 — Venue Insight (Surprise)
Venue-wise chasing win % computed in Apex using full match dataset.
Finding: Chase win rate swings from 40% to 65%+ based purely on venue — venue matters more than toss.

💡 Key Insight That Surprised Me

The stadium you play at is a stronger predictor of match outcome than the toss decision. At certain venues, chasing teams win 65%+ of matches — yet captains still make toss decisions without factoring in venue-specific history.
