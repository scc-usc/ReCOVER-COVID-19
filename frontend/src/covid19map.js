import React, { Component, Fragment } from "react";
import { Map, TileLayer, CircleMarker, Tooltip, LayersControl, LayerGroup } from "react-leaflet";
import ModelAPI from "./modelapi";
import "leaflet/dist/leaflet.css";

import globalLL from "./frontendData/global_lats_longs.txt"
import population from './frontendData/global_population_data.txt'

import Papa from "papaparse";

//const{ Map, TileLayer, CircleMarker, Tooltip, LayersControl, LayerGroup } = React.lazy(() =>import("react-leaflet"));
//React.lazy(import("leaflet/dist/leaflet.css"));

var global_lat_long;
var populationVect;

function parse_lat_long_global(data) {
	global_lat_long = data;
}

function parse_population(data) {
	populationVect = data;
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

function casesPerPersonCalculation(populationNum, numCases) {
	numCases = populationNum/numCases;
	return Math.round(numCases);
}

function numberWithCommas(x) {
	return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

parseData(globalLL, parse_lat_long_global);
parseData(population, parse_population);

const Covid19Marker = ({ caseKey, deathKey, data, center, caseRadius, deathRadius, caseValue, deathValue, population, color, caseOpacity, deathOpacity, stroke, onClick }) => (
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
	<b><span>{data}</span></b><br></br>
	<span>{"Cases: " + numberWithCommas(caseValue) + " (1 in " + numberWithCommas(casesPerPersonCalculation(population, caseValue)) + ")"}</span><br></br>
	<span>{"Deaths: " + numberWithCommas(deathValue) + " (1 in " + numberWithCommas(casesPerPersonCalculation(population, deathValue)) + ")"}</span><br></br>
	</Tooltip>
	</CircleMarker>
	<Tooltip direction="right" opacity={1} sticky={true}>
	<b><span>{data}</span></b><br></br>
	<span>{"Cases: " + numberWithCommas(caseValue) + " (1 in " + numberWithCommas(casesPerPersonCalculation(population, caseValue)) + ")"}</span><br></br>
	<span>{"Deaths: " + numberWithCommas(deathValue) + " (1 in " + numberWithCommas(casesPerPersonCalculation(population, deathValue)) + ")"}</span><br></br>

	</Tooltip>
	</CircleMarker>
	);

const Covid19MarkerList = ({ markers }) => {
	const items = markers.map(({ ...props }) => (
		<Covid19Marker {...props} />
		));
	return <Fragment>{items}</Fragment>;
}

const default_zoom = 4;
class Covid19Map extends Component {

	constructor() 
	{
		super();
		this.modelAPI = new ModelAPI();

		this.state = {
			areasList : [],
			worldCases: [],
			worldDeaths: [],
			markers: [],
			stateMarkers: [],
			countyMarkers: [],
			renderStateCountyMarkers: [],
			us: [],
			renderUS: [],
			callbackCounter: 0,
			mapInitialized: false,
			zoomlevel: default_zoom,
			prev_zoomlevel: default_zoom,
			height: 0,
			width: 0
		};

		this.modelAPI.areas(allAreas =>
		this.setState({
			areasList: allAreas
		})
		);
		this.updateMarkerSizes = this.updateMarkerSizes.bind(this);
		this.updateWindowDimensions = this.updateWindowDimensions.bind(this);

	}

	componentDidMount() {
		this.props.triggerRef(this);
		this.fetchData(this.props.dynamicMapOn);
		this.updateWindowDimensions();
		window.addEventListener("resize", this.updateWindowDimensions);
	}

	componentWillUnmount() {
		window.removeEventListener("resize", this.updateWindowDimensions);
	}

	updateWindowDimensions() {
		this.setState({ width: window.innerWidth, height: window.innerHeight });
	}

	setCaseDeathData() {
		if (this.state.callbackCounter > 1) {
			let callbackCounter = 0;
			this.setState({ callbackCounter });

			if (!this.state.mapInitialized) {
				
				if (typeof(this.state.caseData) != "undefined" && typeof(this.state.deathData) != "undefined") {
					for (var i = 0; i < global_lat_long.length; i++) {
						if (typeof(this.state.caseData[i]) === "undefined" || typeof(this.state.deathData[i]) === "undefined")
						{
							continue;
						}
						
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
									caseRadius: 3 * this.getRadius(caseArea.caseValueTrue, populationVect[i][0]),
									deathRadius: 0.75 * this.getRadius(deathArea.deathValueTrue, populationVect[i][0]),
									caseValue:  caseArea.caseValueTrue,
									deathValue: deathArea.deathValueTrue,
									population: populationVect[i][0],
									color: this.getColor(caseArea.caseValueTrue, populationVect[i][0]),
									caseOpacity: caseOpacity,
									deathOpacity: deathOpacity,
									stroke: true,
									onClick: (e) => this.handleMapClick(e)
								});
								this.state.renderUS.push(this.state.us[0]);
							} else {
								this.state.markers.push({
									key: caseArea.name,
									caseKey: caseArea.name + "-cases",
									deathKey: caseArea.name + "-deaths",
									data: caseArea.name,
									center: [global_lat_long[i][1], global_lat_long[i][2]],
									caseRadius: 3 * this.getRadius(caseArea.caseValueTrue, populationVect[i][0]),
									deathRadius: 0.75 * this.getRadius(deathArea.deathValueTrue, populationVect[i][0]),
									caseValue: caseArea.caseValueTrue,
									deathValue: deathArea.deathValueTrue,
									population: populationVect[i][0],
									color: this.getColor(caseArea.caseValueTrue, populationVect[i][0]),
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
								caseRadius: 3 * this.getRadius(caseArea.caseValueTrue),
								deathRadius: 0.75 * this.getRadius(deathArea.deathValueTrue, populationVect[i][0]),
								caseValue: caseArea.caseValueTrue,
								deathValue: deathArea.deathValueTrue,
								population: populationVect[i][0],
								color: this.getColor(caseArea.caseValueTrue, populationVect[i][0]),
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
					let mapInitialized = true;
					this.setState({ mapInitialized });
				}
			} else {
				let usFound = false;
				let stateCount = 0;
				let markers = this.state.markers;
				let stateMarkers = this.state.stateMarkers;
				let us = this.state.us;
				for (i = 0; i < global_lat_long.length; i++) {
					if (typeof(this.state.caseData[i]) === "undefined" || typeof(this.state.deathData[i]) === "undefined")
						{
							continue;
						}
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
						if (i === 155) {
							usFound = true;
							us[0].caseRadius = 3 * this.getRadius(caseValue, populationVect[i][0]);
							us[0].caseValue = caseValue;
							us[0].color = this.getColor(caseValue, populationVect[i][0]);
							us[0].caseOpacity = caseOpacity;
							us[0].deathRadius = 0.75 * this.getRadius(deathValue, populationVect[i][0]);
							us[0].deathValue = deathValue;
							us[0].deathOpacity = deathOpacity;
						} else {
							if (usFound) {
								markers[i-1].caseRadius = 3 * this.getRadius(caseValue, populationVect[i][0]);
								markers[i-1].caseValue = caseValue;
								markers[i-1].color = this.getColor(caseValue, populationVect[i][0]);
								markers[i-1].caseOpacity = caseOpacity;
								markers[i-1].deathRadius = 0.75 * this.getRadius(deathValue, populationVect[i][0]);
								markers[i-1].deathValue = deathValue;
								markers[i-1].deathOpacity = deathOpacity;
							} else {
								markers[i].caseRadius = 3 * this.getRadius(caseValue, populationVect[i][0]);
								markers[i].caseValue = caseValue;
								markers[i].color = this.getColor(caseValue, populationVect[i][0]);
								markers[i].caseOpacity = caseOpacity;
								markers[i].deathRadius = 0.75 * this.getRadius(deathValue, populationVect[i][0]);
								markers[i].deathValue = deathValue;
								markers[i].deathOpacity = deathOpacity;
							}
						}
					} else {
						stateMarkers[stateCount].caseRadius = 3 * this.getRadius(caseValue, populationVect[i][0]);
						stateMarkers[stateCount].caseValue = caseValue;
						stateMarkers[stateCount].color = this.getColor(caseValue, populationVect[i][0]);
						stateMarkers[stateCount].caseOpacity = caseOpacity;
						stateMarkers[stateCount].deathRadius = 0.75 * this.getRadius(deathValue, populationVect[i][0]);
						stateMarkers[stateCount].deathValue = deathValue;
						stateMarkers[stateCount].deathOpacity = deathOpacity;
						stateCount++;
					}
				}
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
			let callbackCounter = this.state.callbackCounter;
			callbackCounter++;
			this.setState({ caseData, callbackCounter }, this.setCaseDeathData);
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
			let callbackCounter = this.state.callbackCounter;
			callbackCounter++;
			this.setState({ deathData, callbackCounter }, this.setCaseDeathData);
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
			let callbackCounter = this.state.callbackCounter;
			callbackCounter++;
			this.setState({ caseData, callbackCounter }, this.setCaseDeathData);
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
			let callbackCounter = this.state.callbackCounter;
			callbackCounter++;
			this.setState({ deathData, callbackCounter }, this.setCaseDeathData);
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
			let callbackCounter = this.state.callbackCounter;
			callbackCounter += 2;
			this.setState({ caseData, deathData, callbackCounter }, this.setCaseDeathData);
		});
	}

	newCases() {
		if (this.props.days > 0) {
			// prediction
			this.modelAPI.predict_all({
				days: this.props.days,
				model: this.props.confirmed_model
			}, cumulativeInfections => {
				if (this.props.days > 7) {
					this.modelAPI.predict_all({
						days: this.props.days - 7,
						model: this.props.confirmed_model
					}, previousCumulative => {
						let caseData = cumulativeInfections.map((d, index) => {
							return {
								id: d.area.iso_2,
								name: d.area.country,
								state: d.area.state,
								area: d.area,
								caseValue: d.value - previousCumulative[index].value > 0 ? Math.log(d.value - previousCumulative[index].value): 0,
								caseValueTrue: d.value - previousCumulative[index].value > 0 ? d.value - previousCumulative[index].value: 0
							};
						});
						let callbackCounter = this.state.callbackCounter;
						callbackCounter++;
						this.setState({ caseData, callbackCounter }, this.setCaseDeathData);
					});
				} else {
					this.modelAPI.history_cumulative({
						days: this.props.days - 7
					}, previousCumulative => {
						let caseData = cumulativeInfections.map((d, index) => {
							return {
								id: d.area.iso_2,
								name: d.area.country,
								state: d.area.state,
								area: d.area,
								caseValue: d.value - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).value > 0 ? Math.log(d.value - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).value): 0,
								caseValueTrue: d.value - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).value > 0 ? d.value - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).value: 0
							};
						});
						let callbackCounter = this.state.callbackCounter;
						callbackCounter++;
						this.setState({ caseData, callbackCounter }, this.setCaseDeathData);
					});
				}
			});
			this.modelAPI.predict_all({
				days: this.props.days,
				model: this.props.death_model
			}, cumulativeInfections => {
				if (this.props.days > 7) {
					this.modelAPI.predict_all({
						days: this.props.days - 7,
						model: this.props.death_model
					}, previousCumulative => {
						let deathData = cumulativeInfections.map((d, index) => {
							return {
								id: d.area.iso_2,
								name: d.area.country,
								state: d.area.state,
								deathValue: d.value - previousCumulative[index].value > 0 ? Math.log(d.value - previousCumulative[index].value): 0,
								deathValueTrue: d.value - previousCumulative[index].value > 0 ? d.value - previousCumulative[index].value: 0
							};
						});
						let callbackCounter = this.state.callbackCounter;
						callbackCounter++;
						this.setState({ deathData, callbackCounter }, this.setCaseDeathData);
					});
				} else {
					this.modelAPI.history_cumulative({
						days: this.props.days - 7
					}, previousCumulative => {
						let deathData = cumulativeInfections.map((d, index) => {
							return {
								id: d.area.iso_2,
								name: d.area.country,
								state: d.area.state,
								deathValue: d.deathValue - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).deathValue > 0 ? Math.log(d.deathValue - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).deathValue): 0,
								deathValueTrue: d.deathValue - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).deathValue > 0 ? d.deathValue - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).deathValue: 0
							};
						});
						let callbackCounter = this.state.callbackCounter;
						callbackCounter++;
						this.setState({ deathData, callbackCounter }, this.setCaseDeathData);
					});
				}
			});
		} else {
      // history
      this.modelAPI.history_cumulative({
      	days: this.props.days,
      }, historyInfections => {
      	this.modelAPI.history_cumulative({
      		days: this.props.days - 7,
      	}, nextDayCumulative => {
      		let caseData = historyInfections.map((d, index) => {
      			return {
      				id: d.area.iso_2,
      				name: d.area.country,
      				state: d.area.state,
      				caseValue: d.value - nextDayCumulative[index].value > 0 ? Math.log(d.value - nextDayCumulative[index].value): 0,
      				caseValueTrue: d.value - nextDayCumulative[index].value > 0 ? d.value - nextDayCumulative[index].value: 0,
      				deathValue: d.deathValue - nextDayCumulative[index].deathValue > 0 ? Math.log(d.deathValue - nextDayCumulative[index].deathValue): 0,
      				deathValueTrue: d.deathValue - nextDayCumulative[index].deathValue > 0 ? d.deathValue - nextDayCumulative[index].deathValue: 0
      			};
      		});
      		let deathData = caseData;
      		let callbackCounter = this.state.callbackCounter;
      		callbackCounter += 2;
      		this.setState({ caseData, deathData, callbackCounter }, this.setCaseDeathData);
      	});
      });
  }
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
        this.newCases();
    }
}
}

handleMapClick(e) {
	const { onMapClick, onNoData } = this.props;
	var area = e.target.options.data;
	if (area) {
      //console.log("Clicked on " + area);
      // if (area === "US") {
      //   this.renderStatesCounties();
      // }
      // if (area.slice(0, 5) === "US / ") {
      //   this.renderUS();
      // }
      onMapClick(area);
  } else {
  	onNoData(area);
  }
}

getRadius(value, popu) {

	if(this.props.perMillion){
		value = 100000000*value/popu;
	}
	if (value === 0)
		return value;
  	//var radius = Math.log(value / 1000);
  	var radius = 1 + (this.state.zoomlevel)*Math.log(value / 1000)/3;
  	if (radius < 3)
  		radius = 3;

  	//return (this.state.height/1000)*radius;
  	return radius;
  }

  updateMarkerSizes(){
  	var change_factor = this.state.zoomlevel/this.state.prev_zoomlevel;
  	var thesemarkers, i;
  	thesemarkers = this.state.markers;
  	for (i=0; i< thesemarkers.length; i++){
  		thesemarkers[i].deathRadius = change_factor*thesemarkers[i].deathRadius;
  		thesemarkers[i].caseRadius = change_factor*thesemarkers[i].caseRadius;
  	}
  	this.setState({markers: thesemarkers});

  	thesemarkers = this.state.stateMarkers;
  	for (i=0; i< thesemarkers.length; i++){
  		thesemarkers[i].deathRadius = change_factor*thesemarkers[i].deathRadius;
  		thesemarkers[i].caseRadius = change_factor*thesemarkers[i].caseRadius;
  	}
  	this.setState({stateMarkers: thesemarkers});

  	thesemarkers = this.state.us;
  	for (i=0; i< thesemarkers.length; i++){
  		thesemarkers[i].deathRadius = change_factor*thesemarkers[i].deathRadius;
  		thesemarkers[i].caseRadius = change_factor*thesemarkers[i].caseRadius;
  	}
  	this.setState({us: thesemarkers});

  	//this.setState({ markers, stateMarkers, us });
  }

  getColor(d, p) {

  	if(this.props.perMillion){
  		d = 10000000*d/p;
  	}

  	d /= 10000;
  	return d > 100 ? '#800026' :
  	d > 50  ? '#BD0026' :
  	d > 25  ? '#E31A1C' :
  	d > 10  ? '#FC4E2A' :
  	d > 5   ? '#FD8D3C' :
  	d > 2   ? '#FEB24C' :
  	d > 0.5   ? '#FED976' :
  	'#FFEDA0';
  }

  renderUS() {
  	return <Covid19MarkerList markers={this.state.us} />;
  }

  renderStates() {
  	return <Covid19MarkerList markers={this.state.stateMarkers} />;
  }

  // renderUS() {
  //   let renderUS = this.state.us;
  //   let renderStateCountyMarkers = [];
  //   this.setState({ renderUS, renderStateCountyMarkers });
  // }

  // renderStatesCounties() {
  //   let renderStateCountyMarkers = this.state.stateMarkers;
  //   let renderUS = [];
  //   this.setState({ renderStateCountyMarkers, renderUS });
  // }

  render() {
  	return (
  		<div>
  		<Map
  		style={{ height: "42vh", width: "100%" }}
  		zoom={default_zoom}
  		minZoom={1}
  		center={[37.8, -96]}
  		ref={(ref) => { this.map = ref; }}
  		onzoomend={() => {this.setState({prev_zoomlevel: this.state.zoomlevel}); this.setState({zoomlevel: this.map.leafletElement.getZoom()}); this.updateMarkerSizes()}}
  		maxBounds={[
  			[90, -Infinity],
  			[-90, Infinity]
  			]}
  			worldCopyJump={true}
  			>
  			<TileLayer url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png" />
  			<Covid19MarkerList markers={this.state.markers} />
          {/* <Covid19MarkerList markers={this.state.renderUS} />
      <Covid19MarkerList markers={this.state.renderStateCountyMarkers} /> */}
      <LayersControl position="topright">
      <LayersControl.BaseLayer name="Show US Country">
      <LayerGroup>
      {this.renderUS()}
      </LayerGroup>
      </LayersControl.BaseLayer>
      <LayersControl.BaseLayer checked name="Show US State">
      <LayerGroup>
      {this.renderStates()}
      </LayerGroup>
      </LayersControl.BaseLayer>
      </LayersControl>
      </Map>
      </div>
      )
  }
}

export default Covid19Map;
