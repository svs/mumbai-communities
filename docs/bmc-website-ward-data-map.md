# BMC Website — Ward-Level Data Map

Crawled Feb 2026 via Playwright. Base URL: `https://portal.mcgm.gov.in`

## 1. Ward List

**URL:** `/irj/portal/anonymous/qlallward`

24 administrative wards (A through T, with North/South/East/West splits). Each ward has:

- **RTI page** — e.g. `/irj/portal/anonymous/qlacaward` (Ward A)
- **Docs page** — e.g. `/irj/portal/anonymous/qlwrda` (Ward A)

Pattern for all wards:

| Ward | RTI | Docs |
|------|-----|------|
| A | `qlacaward` | `qlwrda` |
| B | `qlacbward` | `qlwrdb` |
| C | `qlaccward` | `qlwrdc` |
| D | `qlacdward` | `qlwrdd` |
| E | `qlaceward` | `qlwarde` |
| F North | `qlrtiacfward` | `qlwrdfn` |
| F South | `qlacfsward` | `qlwrdfs` |
| G North | `qlacgnward` | `qlwrdgn` |
| G South | `qlacgn` | `qlacgswarddocs` |
| H East | `qlacheward` | `qlachewarddocs` |
| H West | `qlachwward` | `qlwrdhw` |
| K East | `qlackeward` | `qlackewarddocs` |
| K West | `qlackwward` | `qlwrdkw` |
| L | `qlaclward` | `qlwrdl` |
| M East | `qlacmeward` | `qlwrdme` |
| M West | `qlacmwward` | `qlwrdmw` |
| N | `qlacnward` | `qlwrdn` |
| P North | `qlacpnward` | `qlwrdpn` |
| P South | `qlacpsward` | `qlwrdps` |
| R North | `qlacrnward` | `qlwrdrn` |
| R South | `qlacrsouthward` | `qlwrdrs` |
| R Central | `qlacrcward` | `qlacrcwarddocs` |
| S | `qlacsward` | `qlwrds` |
| T | `qlactward` | `qlwrdt` |

Last updated 31/12/2016 (stale).

## 2. BMC on Maps (ArcGIS-based, Beta)

Under **Maps, Reports & Insights > BMC on Maps**. All use embedded ArcGIS from `mcgm.maps.arcgis.com`.

| Page | URL slug | Content |
|------|----------|---------|
| Wards & Offices | `BMC-on-Map-Wards-Offices` | 24 ward boundaries + ward office locations |
| Near Me - Facilities | `BMC-on-Map-NearMe-Amenities-Facilities` | Location-based amenity search |
| Gardens & Open Spaces | `BMC-on-Map-Amenities-Gardens-OpenSpaces` | Parks by ward |
| Parking Lots | `BMC-on-Map-Facilities-ParkingLots` | Parking by ward |
| Toilets | `BMC-on-Map-Facilities-Toilets` | Public toilets by ward |
| Health | `BMC-on-Map-Facilities-Health` | Health facilities by ward |
| Schools | `BMC-on-Map-Facilities-Schools` | BMC schools by ward |
| Transport (BEST) | `BMC-on-Map-Transport-BEST` | Bus routes/stops |
| Building ID | `MyBMC-Building-ID` | Building lookup |

## 3. BMC General Election 2025

**URL:** `/irj/portal/anonymous/qlBMCElect2025`

File repository with folders:

| Folder | Content | Date |
|--------|---------|------|
| Ward Formation | Prabhag map PDFs (our source data for boundary tracing) | Oct 2025 |
| Prabhag Reservation 2025 | Reservation categories per prabhag | Nov 2025 |
| Prabhag Voter List 2025 | Voter lists per prabhag | Jan 2026 |
| Final Polling Station Address List | With voter counts per station | Jan 2026 |
| Polling Booth Location List | Booth addresses | Dec 2025 |
| List of Contesting Candidates | Per prabhag | Jan 2026 |
| Winning Candidate Gazette | Election results | Jan 2026 |
| Candidate Affidavits | At `electiondata.mcgm.gov.in` | Jan 2026 |
| Jodpatra 3 & 4 | Supplementary schedules | Jan 2026 |
| Election Program | Schedule/logistics | Dec 2025 |
| Shifted Polling Booth List | Changed booth locations | Jan 2026 |
| Public Notice | Official notices | Dec 2025 |

Also: nomination form PDFs at the root level.

## 4. Ward-Level Disclosures

- **Ward Wise Projections** — `/irj/portal/anonymous/qlwardwise1` (financial projections by ward)
- **Budget** — `/irj/portal/anonymous/qlbudgets`
- **Annual Accounts** — `/irj/portal/anonymous/qlAAccounts`
- **Audited Annual Accounts** — 2018-19 through 2022-23 available

## 5. Other Ward-Adjacent Services

| Service | URL | Data |
|---------|-----|------|
| Desilting Dashboard | `swd.mcgm.gov.in/WMS2025/` | Storm water drain work by ward |
| CC Road Progress | `roads.mcgm.gov.in/publicdashboard/` | Concrete road work by ward |
| Aapla Davakhana | PDF on portal | HBT clinics/polyclinics with locations |
| Property Tax | `ptaxportal.mcgm.gov.in` | Ward-level tax data |
| Civic Complaints | `/irj/portal/anonymous/qlCLCComp` | Ward-level complaint registration |
| Smile Council | `smile.mcgm.gov.in` | Ward-level civic data |
| OneMCGM GIS | `gis.mcgm.gov.in:4430/maps` | Employee-facing GIS portal |
| Disaster Management | `dm.mcgm.gov.in` | Emergency info |
| Swimming Pools | `swimmingpool.mcgm.gov.in` | Pool bookings |
| Veterinary Health | `vhd.mcgm.gov.in` | Dog licenses, complaints |

## Notes for wardpress.in

The richest ward-level data sources to integrate:

1. **ArcGIS map layers** — health facilities, schools, toilets, gardens, parking (all geocoded by ward). Could potentially query the ArcGIS REST API directly.
2. **Election 2025 data** — prabhag maps, voter lists, polling stations, candidates, results. All as PDFs in the KM repository.
3. **Ward Wise Projections** — financial/budget data per ward.
4. **Desilting & Roads dashboards** — infrastructure work progress per ward.
