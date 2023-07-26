![GitHub](https://img.shields.io/badge/license-GPL--3.0-blue)

## Scraping Travel Information

## Table of Contents

1.  [Description](#description)
2.  [Usage](#usage)
3.  [Scraped Travel Information](#scraped-trave-information)
4.  [Contributors](#contributors)
5.  [License](#license)

## Description

Repository of scripts to scrape routing information such as travel time and distance between visited postcodes of a given set of trips. This project was undertaken at Utrecht University, The Netherlands, during 2022-2023 by Marco Pellegrino and a team of contributors.

Implemented means of transport:

*   Walk
*   Bike
*   Car
*   Bus/Tram/Underground + Walk
*   Train + Bus/Tram/Underground + Walk

The code makes use of the R library OpenTripPlanner: Malcolm Morgan, Marcus Young, Robin Lovelace, Layik Hama (2019). "OpenTripPlanner for R." Journal of Open Source Software, 4(44), 1926. [doi:10.21105/joss.01926](https://doi.org/10.21105/joss.01926).

OpenTripPlanner version used: [2.2.0](https://docs.opentripplanner.org/en/v2.2.0/)

## Data

The software operates by integrating OpenStreetMap \\cite{OpenStreetMap} maps with GTFS (General Transit Feed Specification) data. OpenStreetMap is used to calculate information regarding walking, biking, and driving by associating speeds with a network of streets for each mode of transportation. On the other hand, GTFS data provides details about public transport, including buses, trams, and trains.

The tool initially [creates a graph](build_graph.R) by combining the OpenStreetMap and GTFS data, which is then used to retrieve travel information within the network.

Considering that the simulation includes trips that extend beyond the case-study area, data about the entirety of the Netherlands is used:  

*   OpenStreetMap data from [Geofabrik](https://download.geofabrik.de/europe/netherlands.html)  
*   GTFS data from [Transitlan](https://www.transit.land/feeds/f-u-nl)

## Usage

R scripts leveraging the OpenTripPlanner R library have been developed. These scripts pre-calculate routing information for the trips specified in the activity schedules.

*   [`generate_OD.R`](generate_OD.R). The script generated the origin-destination matrix for the given located activity schedule.
*   [`routing_walk_bike_car.R`](routing_walk_bike_car.R). The script scrapes the travel information for walking, biking, and car driving. The travel information is computed only once per origin-destination, since the travel times and distances remain the same in both directions.
*   [`routing_bus.R`](routing_bus.R). The script scrapes the travel information for buses and trams.
*   [`routing_train.R`](routing_train.R). The script scrapes the travel information for trains, including trips that are also composed of legs of buses and/or trams.

## Scraped Travel Information

|   | **Walk** | **Bike** | **Car** | **Bus/Tram** | **Train + optionally Bus/Tram** |
| --- | --- | --- | --- | --- | --- |
| Total travel time (minutes) | x | x | x | x | x |
| Walk time (minutes) | x |   |   | x | x |
| Time by bus (minutes) |   |   |   | x | x |
| Time by train (minutes) |   |   |   |   | x |
| Waiting time (minutes) |   |   |   | x | x |
| Total distance (km) | x | x | x | x | x |
| Walk distance (km) |   |   |   | x | x |
| Distance by bus/tram (km) |   |   |   | x | x |
| Distance by train (km) |   |   |   |   | x |
| Number of changes |   |   |   | x | x |
| Postcode PC6 bus/tram/train stop of leg crossing outside area |   |   |   | x | x |

## Contributors

This project was made possible thanks to the hard work and contributions from:

*   Marco Pellegrino (Author)
*   Jan de Mooij
*   Tabea Sonnenschein
*   Mehdi Dastani
*   Dick Ettema
*   Brian Logan
*   Judith A. Verstegen

## License

This repository is licensed under the GNU General Public License v3.0 (GPL-3.0). For more details, see the [LICENSE](LICENSE) file.