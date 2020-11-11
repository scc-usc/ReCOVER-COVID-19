import React, { Component, Fragment } from "react";
import { Map, TileLayer, CircleMarker, Tooltip, LayersControl, LayerGroup } from "react-leaflet";
import ModelAPI from "./modelapi";
import "leaflet/dist/leaflet.css";

import globalLL from "./frontendData/global_lats_longs.txt"

import Papa from "papaparse";

var global_lat_long;

function parse_lat_long_global(data) {
    global_lat_long = data;
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

const Covid19Marker = ({ caseKey, deathKey, data, center, caseRadius, deathRadius, caseValue, deathValue, color, caseOpacity, deathOpacity, stroke, onClick }) => (
  <CircleMarker
    key={deathKey}
    data={data}
    center={center}
    radius={deathRadius}
    fillColor="black"
    fillOpacity={deathOpacity}
    stroke={false}
    onClick={onClick}
  >
    <CircleMarker
      key={caseKey}
      data={data}
      center={center}
      radius={caseRadius}
      color="white"
      weight={1.5}
      fillColor={color}
      fillOpacity={caseOpacity}
      stroke={true}
      onClick={onClick}
    >
      <Tooltip direction="right" opacity={1} sticky={true}>
        <span>{data}</span><br></br>
        <span>{"Cases: " + caseValue}</span><br></br>
        <span>{"Deaths: " + deathValue}</span>
      </Tooltip>
    </CircleMarker>
    <Tooltip direction="right" opacity={1} sticky={true}>
      <span>{data}</span><br></br>
      <span>{"Cases: " + caseValue}</span><br></br>
      <span>{"Deaths: " + deathValue}</span>
    </Tooltip>
  </CircleMarker>
);

const Covid19MarkerList = ({ markers }) => {
  const items = markers.map(({ ...props }) => (
    <Covid19Marker {...props} />
  ));
  return <Fragment>{items}</Fragment>;
}

class Covid19Map extends Component {

  constructor() {
    super();
    this.modelAPI = new ModelAPI();

    this.state = {
      areasList : [],
      worldCases: [],
      worldDeaths: [],
      markers: [],
      stateMarkers: [],
      us: [],
      callbackCounter: 0,
      mapInitialized: false
    };

    this.modelAPI.areas(allAreas =>
      this.setState({
        areasList: allAreas
      })
    );
  }

  componentDidMount() {
    this.props.triggerRef(this);
    this.fetchData(this.props.dynamicMapOn);
  }

  setCaseDeathData() {
    if (this.state.callbackCounter > 1) {
      this.state.callbackCounter = 0;

      if (!this.state.mapInitialized) {
        this.state.mapInitialized = true;
        if (typeof(this.state.caseData) != "undefined" && typeof(this.state.deathData) != "undefined") {
          for (var i = 0; i < global_lat_long.length; i++) {
            let caseArea = this.state.caseData[i];
            let deathArea = this.state.deathData[i];
            let caseOpacity = 0.5;
            if (caseArea.valueTrue === 0) {
              caseOpacity = 0;
            }
            let deathOpacity = 1;
            if (deathArea.valueTrue === 0) {
              deathOpacity = 0;
            }
            if (i < 184) {
              let compare = this.state.areasList[i].country + " ";
              if ("US " === compare) {
                this.state.us.push({
                  key: caseArea.name,
                  caseKey: caseArea.name + "-cases",
                  deathKey: caseArea.name + "-deaths",
                  data: caseArea.name,
                  center: [global_lat_long[i][1], global_lat_long[i][2]],
                  caseRadius: 4 * this.getRadius(caseArea.caseValueTrue),
                  deathRadius: this.getRadius(deathArea.deathValueTrue),
                  caseValue: caseArea.caseValueTrue,
                  deathValue: deathArea.deathValueTrue,
                  color: this.getColor(caseArea.caseValueTrue),
                  caseOpacity: caseOpacity,
                  deathOpacity: deathOpacity,
                  stroke: true,
                  onClick: (e) => this.handleMapClick(e)
                });
              } else {
                this.state.markers.push({
                  key: caseArea.name,
                  caseKey: caseArea.name + "-cases",
                  deathKey: caseArea.name + "-deaths",
                  data: caseArea.name,
                  center: [global_lat_long[i][1], global_lat_long[i][2]],
                  caseRadius: 4 * this.getRadius(caseArea.caseValueTrue),
                  deathRadius: this.getRadius(deathArea.deathValueTrue),
                  caseValue: caseArea.caseValueTrue,
                  deathValue: deathArea.deathValueTrue,
                  color: this.getColor(caseArea.caseValueTrue),
                  caseOpacity: caseOpacity,
                  deathOpacity: deathOpacity,
                  stroke: true,
                  onClick: (e) => this.handleMapClick(e)
                });
              }
            } else {
              this.state.stateMarkers.push({
                key: caseArea.id,
                caseKey: caseArea.state + "-cases",
                deathKey: caseArea.state + "-deaths",
                data: caseArea.name +  " / " + caseArea.state,
                center: [global_lat_long[i][1], global_lat_long[i][2]],
                caseRadius: 4 * this.getRadius(caseArea.caseValueTrue),
                deathRadius: this.getRadius(deathArea.deathValueTrue),
                caseValue: caseArea.caseValueTrue,
                deathValue: deathArea.deathValueTrue,
                color: this.getColor(caseArea.caseValueTrue),
                display: "none",
                caseOpacity: caseOpacity,
                deathOpacity: deathOpacity,
                stroke: true,
                onClick: (e) => this.handleMapClick(e)
              });
            }
          }
          let markers = this.state.markers;
          let stateMarkers = this.state.stateMarkers;
          let us = this.state.us;
          this.setState({ markers, stateMarkers, us });
        }
      } else {
        let usFound = false;
        let stateCount = 0;
        for (var i = 0; i < global_lat_long.length; i++) {
          let caseValue = this.state.caseData[i].caseValueTrue;
          let deathValue = this.state.deathData[i].deathValueTrue;
          let caseOpacity = 0.5;
          if (caseValue === 0) {
            caseOpacity = 0;
          }
          let deathOpacity = 1;
          if (deathValue === 0) {
            deathOpacity = 0;
          }
          if (i < 184) {
            if (i == 155) {
              usFound = true;
              this.state.us[0].caseRadius = 4 * this.getRadius(caseValue);
              this.state.us[0].caseValue = caseValue;
              this.state.us[0].color = this.getColor(caseValue);
              this.state.us[0].caseOpacity = caseOpacity;
              this.state.us[0].deathRadius = this.getRadius(deathValue);
              this.state.us[0].deathValue = deathValue;
              this.state.us[0].deathOpacity = deathOpacity;
            } else {
              if (usFound) {
                this.state.markers[i-1].caseRadius = 4 * this.getRadius(caseValue);
                this.state.markers[i-1].caseValue = caseValue;
                this.state.markers[i-1].color = this.getColor(caseValue);
                this.state.markers[i-1].caseOpacity = caseOpacity;
                this.state.markers[i-1].deathRadius = this.getRadius(deathValue);
                this.state.markers[i-1].deathValue = deathValue;
                this.state.markers[i-1].deathOpacity = deathOpacity;
              } else {
                this.state.markers[i].caseRadius = 4 * this.getRadius(caseValue);
                this.state.markers[i].caseValue = caseValue;
                this.state.markers[i].color = this.getColor(caseValue);
                this.state.markers[i].caseOpacity = caseOpacity;
                this.state.markers[i].deathRadius = this.getRadius(deathValue);
                this.state.markers[i].deathValue = deathValue;
                this.state.markers[i].deathOpacity = deathOpacity;
              }
            }
          } else {
            this.state.stateMarkers[stateCount].caseRadius = 4 * this.getRadius(caseValue);
            this.state.stateMarkers[stateCount].caseValue = caseValue;
            this.state.stateMarkers[stateCount].color = this.getColor(caseValue);
            this.state.stateMarkers[stateCount].caseOpacity = caseOpacity;
            this.state.stateMarkers[stateCount].deathRadius = this.getRadius(deathValue);
            this.state.stateMarkers[stateCount].deathValue = deathValue;
            this.state.stateMarkers[stateCount].deathOpacity = deathOpacity;
            stateCount++;
          }
        }
        let markers = this.state.markers;
        let stateMarkers = this.state.stateMarkers;
        let us = this.state.us;
        this.setState({ markers, stateMarkers, us });
      }
    }
  }

  getCaseDeathData() {
    this.modelAPI.cumulative_infections(cumulativeInfections => {
      let caseData = cumulativeInfections.map(d => {
        return {
          id: d.area.iso_2,
          name: d.area.country,
          state: d.area.state,
          area: d.area,
          caseValue: Math.log(d.max_percentage),
          caseValueTrue: d.value
        };
      });
      this.state.callbackCounter++;
      this.setState({ caseData }, this.setCaseDeathData);
    });
    this.modelAPI.cumulative_death({
      days: 0
    }, cumulativeDeath => {
      let deathData = cumulativeDeath.map(d => {
        return {
          id: d.area.iso_2,
          name: d.area.country,
          state: d.area.state,
          area: d.area,
          deathValue: Math.log(d.max_percentage),
          deathValueTrue: d.value
        };
      });
      this.state.callbackCounter++;
      this.setState({ deathData }, this.setCaseDeathData);
    });
  }

  predictCaseDeathData() {
    this.modelAPI.predict_all({
      days: this.props.days,
      model: this.props.confirmed_model
    }, cumulativeInfections => {
      let caseData = cumulativeInfections.map(d => {
        return {
          id: d.area.iso_2,
          name: d.area.country,
          state: d.area.state,
          area: d.area,
          caseValue: Math.log(d.max_val_percentage),
          caseValueTrue: d.value
        };
      });
      this.state.callbackCounter++;
      this.setState({ caseData }, this.setCaseDeathData);
    });
    this.modelAPI.predict_all({
      days: this.props.days,
      model: this.props.death_model
    }, cumulativeInfections => {
      let deathData = cumulativeInfections.map(d => {
        return {
          id: d.area.iso_2,
          name: d.area.country,
          state: d.area.state,
          area: d.area,
          deathValue: Math.log(d.max_death_percentage),
          deathValueTrue: d.value
        };
      });
      this.state.callbackCounter++;
      this.setState({ deathData }, this.setCaseDeathData);
    });
  }

  getHistoryCumulative() {
    this.modelAPI.history_cumulative({
      days: this.props.days
    }, historyCumulative => {
      let caseData = historyCumulative.map(d => {
        return {
          id: d.area.iso_2,
          name: d.area.country,
          state: d.area.state,
          area: d.area,
          caseValue: Math.log(d.max_val_percentage),
          caseValueTrue: d.value,
          deathValue: Math.log(d.max_death_percentage),
          deathValueTrue: d.deathValue
        };
      });
      let deathData = caseData;
      this.state.callbackCounter += 2;
      this.setState({ caseData, deathData }, this.setCaseDeathData);
    });
  }

  fetchData(dynamicMapOn) {
    if (!dynamicMapOn || (this.props.confirmed_model === "" && this.props.death_model === "")) {
      // without dynamic map, show cumulative cases to date
      this.getCaseDeathData();
    } else {
      // with dynamic map
      if (this.props.statistic === "cumulative") {
        if (this.props.days > 0) {
          this.predictCaseDeathData();
        } else {
          // show history cumulative
          this.getHistoryCumulative();
        }
      } else {
        // new cases
      }
    }
  }

  handleMapClick(e) {
    const { onMapClick, onNoData } = this.props;
    var area = e.target.options.data;
    if (area) {
      // console.log("Clicked on " + area);
      onMapClick(area);
    } else {
      onNoData(area);
    }
  }

  getRadius(value) {
    if (value === 0)
      return value;
  	var radius = Math.log(value / 100);

  	if (radius < 1)
  		radius = 1;

  	return radius;
  }

  getColor(d) {
    d /= 10000;
   	return d > 100 ? '#800026' :
           d > 50  ? '#BD0026' :
           d > 20  ? '#E31A1C' :
           d > 10  ? '#FC4E2A' :
           d > 5   ? '#FD8D3C' :
           d > 2   ? '#FEB24C' :
           d > 1   ? '#FED976' :
                      '#FFEDA0';
  }

  renderFirst() {
    return <Covid19MarkerList markers={this.state.us} />;
  }

  renderSecond() {
    return <Covid19MarkerList markers={this.state.stateMarkers} />;
  }

  render() {
    return (
      <div>
        <Map
          style={{ height: "880px", width: "100%" }}
          zoom={4}
          minZoom={3}
          center={[37.8, -96]}
          ref={(ref) => { this.map = ref; }}
          maxBounds={[
            [90, -Infinity],
            [-90, Infinity]
          ]}
          worldCopyJump={true}
        >
          <TileLayer url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png" />
          <Covid19MarkerList markers={this.state.markers} />
          <LayersControl position="topright">
            <LayersControl.BaseLayer checked name="Show US Country">
              <LayerGroup>
                {this.renderFirst()}
              </LayerGroup>
            </LayersControl.BaseLayer>
            <LayersControl.BaseLayer name="Show US State">
              <LayerGroup>
                {this.renderSecond()}
              </LayerGroup>
            </LayersControl.BaseLayer>
          </LayersControl>
        </Map>
      </div>
    )
  }
}

export default Covid19Map;