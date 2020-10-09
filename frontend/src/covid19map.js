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

import Papa from "papaparse";

var global_lat_long;
var combined_global_data;
var us_lat_long;
var combined_us_data;

function parse_lat_long_global(data) {
    global_lat_long = data;
}

function combineGlobal(data) {
    combined_global_data = data;
    for (var i = 0; i < global_lat_long.length; i++) {
        combined_global_data[i+1].push(global_lat_long[i][1]);
        combined_global_data[i+1].push(global_lat_long[i][2]);
    }
    console.log(combined_global_data);
}

function parse_lat_long_us(data) {
    us_lat_long = data;
}

function combineUs(data) {
    combined_us_data = data;
    for (var i = 0; i < us_lat_long.length; i++) {
        combined_us_data[i+1].push(us_lat_long[i][1]);
        combined_us_data[i+1].push(us_lat_long[i][2]);
    }
    console.log(combined_us_data);
}

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
parseData(usLL, parse_lat_long_us);
parseData(us_data, combineUs);

class Covid19Map extends Component {

  handleMapClick(data, e) {
    const { onMapClick, onNoData } = this.props;
    var area = data.country[e.target.options.children[0].key].name;
    if (area) {
      console.log("Clicked on " + area);
      onMapClick(area);
    } else {
      onNoData(area);
    }
  }

  getRadius(population) {
  	var radius = Math.log(population / 1000000);

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

    			{data.country.map((country, k) => {
    				return (
    					<CircleMarker
    						key={k}
    						center={[country["coordinates"][0], country["coordinates"][1]]}
    						radius={10 * this.getRadius(country["population"])}
    						color={this.getColor(country["population"] / 1000000)}
    						fillOpacity={0.5}
                stroke={false}
                onClick={ (e) => this.handleMapClick(data, e)}
    					>
    						<CircleMarker
    							key={k}
    							center={[country["coordinates"][0], country["coordinates"][1]]}
    							radius={2 * this.getRadius(country["population"])}
    							color="black"
    							fillOpacity={1}
    							stroke={false}
    						></CircleMarker>
    						<Tooltip direction="right" offset={[-8, -2]} opacity={1}>
    							<span>{country["name"] + ": Population " + country["population"]}</span>
    						</Tooltip>
    					</CircleMarker>
    					)
    			})
    			}
    		</Map>
    	</div>
    );
  }
}

export default Covid19Map;