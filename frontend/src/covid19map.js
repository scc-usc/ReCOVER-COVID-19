import React, { Component } from "react";
import { Circle, Map, Marker, Popup, TileLayer, CircleMarker, Tooltip } from "react-leaflet";
import ModelAPI from "./modelapi";
import { areaToStr, strToArea } from "./covid19util";
import "leaflet/dist/leaflet.css";
import data from "./countries";

import globalLL from "./frontendData/global_lats_longs.txt"
import global_data from "./frontendData/global_data.csv"
import usLL from "./frontendData/us_lats_longs.txt"
import us_data from "./frontendData/us_data.csv"
import usDeath from './frontendData/us_deaths.csv'
import globalDeath from './frontendData/global_deaths.csv'

import Papa from "papaparse";

var global_lat_long;
// var us_lat_long;

var combined_global_data = { country: [ { "name": "", "coordinates": [0, 0], "cases": [0], "deaths": [0]} ] };
// var combined_us_data;
// var us_death;
var global_death;

function parse_lat_long_global(data) {
    global_lat_long = data;
}

// function readUsDeath(data) {
//   us_death = data;
// }

function readGlobalDeath(data) {
  global_death = data;
}

function combineGlobal(data) {
  for (var i = 0; i < global_lat_long.length; i++) {
      data[i+1].push(global_lat_long[i][1]);
      data[i+1].push(global_lat_long[i][2]);
  }
  combined_global_data.country = [];
  for (var i = 0; i < data.length - 2; i++) {
    var id = data[i+1].splice(0,1)[0];
    var name = data[i+1].splice(0,1)[0];
    var coordinates = data[i+1].splice(data[i+1].length-2, data[i+1].length-1);
    var deathID = global_death[i+1].splice(0,1);
    var deathName = global_death[i+1].splice(0,1);
    var country = {"name": name, "coordinates": coordinates, "cases": data[i+1], "deaths": global_death[i+1]};
    combined_global_data.country.push(country);
  }
  console.log(combined_global_data);
}

// function parse_lat_long_us(data) {
//     us_lat_long = data;
// }

// function combineUs(data) {
//     combined_us_data = data;
//     for (var i = 0; i < us_lat_long.length; i++) {
//         combined_us_data[i+1].push(us_lat_long[i][1]);
//         combined_us_data[i+1].push(us_lat_long[i][2]);
//     }
//     console.log(combined_us_data);
// }

function parseData(url, callBack) {
    Papa.parse(url, {
        download: true,
        dynamicTyping: true,
        complete: function(results) {
            callBack(results.data);
        }
    });
}

parseData(globalLL, parse_lat_long_global);
parseData(global_data, combineGlobal);
// parseData(usLL, parse_lat_long_us);
// parseData(us_data, combineUs);
// parseData(usDeath, readUsDeath);
parseData(globalDeath, readGlobalDeath);

class Covid19Map extends Component {

  /*fetchData(dynamicMapOn, date) {
    if (!dynamicMapOn || (this.props.confirmed_model === "" && this.props.death_model === "")) {
      // without dynamic map, show cumulative cases to date
      this.modelAPI.cumulative_infections(cumulativeInfections => {
        let caseData = cumulativeInfections.map(d => {
          return {
            id: d.area.iso_2,
            value: Math.log(d.max_percentage),
            valueTrue: d.value,
            area: d.area
          };
        });
        this.setState({ caseData }, this.resetMap);
      });
      this.modelAPI.cumulative_death({
        days: 0
      }, cumulativeDeath => {
        let deathData = cumulativeDeath.map(d => {
          return {
            id: d.area.iso_2,
            value: Math.log(d.max_percentage),
            valueTrue: d.value,
            area: d.area
          };
        });
        this.setState({ deathData }, this.resetMap);
      });
    } else {
      // with dynamic map
      if (this.props.statistic === "cumulative") {
        if (this.props.days > 0) {
          this.modelAPI.predict_all({
            days: this.props.days,
            model: this.props.confirmed_model
          }, cumulativeInfections => {
            let caseData = cumulativeInfections.map(d => {
              return {
                id: d.area.iso_2,
                value: Math.log(d.max_val_percentage),
                valueTrue: d.value,
                area: d.area
              };
            });
            this.setState({ caseData }, this.resetMap);
          });
          this.modelAPI.predict_all({
            days: this.props.days,
            model: this.props.death_model
          }, cumulativeInfections => {
            let deathData = cumulativeInfections.map(d => {
              return {
                id: d.area.iso_2,
                value: Math.log(d.max_death_percentage),
                valueTrue: d.value,
                area: d.area
              };
            });
            this.setState({ deathData }, this.resetMap);
          });
        } else {
          // show history cumulative
          this.modelAPI.history_cumulative({
            days: this.props.days
          }, historyCumulative => {
            let caseData = historyCumulative.map(d => {
              return {
                id: d.area.iso_2,
                value: Math.log(d.max_val_percentage),
                valueTrue: d.value,
                area: d.area
              };
            });
            this.setState({ caseData }, this.resetMap);
          });
          this.modelAPI.history_cumulative({
            days: this.props.days,
          }, historyCumulative => {
            let deathData = historyCumulative.map(d => {
              return {
                id: d.area.iso_2,
                value: Math.log(d.max_death_percentage),
                valueTrue: d.deathValue,
                area: d.area
              };
            });
            this.setState({ deathData }, this.resetMap)
          })
        }
      }
    }
  }*/

  handleMapClick( e) {
    const { onMapClick, onNoData } = this.props;
    var area = e.target.options.data;
    if (area) {
      console.log("Clicked on " + area);
      onMapClick(area);
    } else {
      onNoData(area);
    }
  }

  getRadius(value) {
    // var radius = Math.log(value / 1000000);
    if (value == 0)
      return value;
  	var radius = Math.log(value / 100);

  	if (radius < .5)
  		radius = .5;

  	return radius;
  }

  getColor(d) {
   	return d > 100 ? '#800026' :
           d > 50  ? '#BD0026' :
           d > 20  ? '#E31A1C' :
           d > 10  ? '#FC4E2A' :
           d > 5   ? '#FD8D3C' :
           d > 2   ? '#FEB24C' :
           d > 1   ? '#FED976' :
                      '#FFEDA0';
  }

  render() {

    // var centerLat = (data.minLat + data.maxLat) / 2;
    // var distanceLat = data.maxLat - data.minLat;
    // var bufferLat = distanceLat * 0.05;
    // var centerLong = (data.minLong + data.maxLong) / 2;
    // var distanceLong = data.maxLong - data.minLong;
    // var bufferLong = distanceLong * 0.05;

    return (
        //this.parseData(csvFile, doStuff)
    	<div>
    		<Map
    			style={{ height: "880px", width: "100%" }}
          zoom={4}
          center={[37.8, -96]}
    			// center={[centerLat, centerLong]}
    			// bounds={[
    			// 	[data.minLat - bufferLat, data.minLong - bufferLong],
    			// 	[data.maxLat + bufferLat, data.maxLong - bufferLong]
    			// ]}
    		>
    			<TileLayer url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png" />

          {combined_global_data.country.map((country, k) => {
            return (
              <CircleMarker
                key={k}
                data={country["name"]}
                center={[country["coordinates"][0], country["coordinates"][1]]}
                radius={this.getRadius(country["deaths"][country["deaths"].length-1])}
                color="black"
                fillOpacity={1}
                stroke={false}
                onClick={ (e) => this.handleMapClick(e) }
              >
                <CircleMarker
                  key={k}
                  data={country["name"]}
                  center={[country["coordinates"][0], country["coordinates"][1]]}
                  radius={5 * this.getRadius(country["cases"][country["cases"].length-1])}
                  color={this.getColor(country["cases"][country["cases"].length-1] / 10000)}
                  fillOpacity={0.5}
                  stroke={false}
                  onClick={ (e) => this.handleMapClick(e)}
                >
                  <Tooltip direction="right" opacity={1} sticky={true}>
                    <span>{country["name"]}</span><br></br>
                    <span>{"Cases: " + country["cases"][country["cases"].length-1]}</span><br></br>
                    <span>{"Deaths: " + country["deaths"][country["deaths"].length-1]}</span>
                  </Tooltip>
                </CircleMarker>
                <Tooltip direction="right" opacity={1} sticky={true}>
                  <span>{country["name"]}</span><br></br>
                  <span>{"Cases: " + country["cases"][country["cases"].length-1]}</span><br></br>
                  <span>{"Deaths: " + country["deaths"][country["deaths"].length-1]}</span>
                </Tooltip>
              </CircleMarker>
            )
          })}

    			{/* {data.country.map((country, k) => {
    				return (
              <CircleMarker
                key={k}
                data={country["name"]}
                center={[country["coordinates"][0], country["coordinates"][1]]}
                radius={2 * this.getRadius(country["population"])}
                color="black"
                fillOpacity={1}
                stroke={false}
                onClick={ (e) => this.handleMapClick(e)}
              >
                <CircleMarker
                  key={k}
                  data={country["name"]}
                  center={[country["coordinates"][0], country["coordinates"][1]]}
                  radius={10 * this.getRadius(country["population"])}
                  color={this.getColor(country["population"] / 1000000)}
                  fillOpacity={0.5}
                  stroke={false}
                  onClick={ (e) => this.handleMapClick(e)}
                >
                  <Tooltip direction="right" opacity={1} sticky={true}>
                    <span>{country["name"] + ": Population " + country["population"]}</span>
                  </Tooltip>
                </CircleMarker>
                <Tooltip direction="right" opacity={1} sticky={true}>
    							<span>{country["name"] + ": Population " + country["population"]}</span>
    						</Tooltip>
              </CircleMarker>
    				)
    			})
    			} */}
    		</Map>
    	</div>
    );
  }
}

export default Covid19Map;