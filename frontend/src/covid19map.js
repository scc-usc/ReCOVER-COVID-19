import React, { Component } from "react";
import { Circle, Map, Marker, Popup, TileLayer } from "react-leaflet";
import ModelAPI from "./modelapi";
import { areaToStr, strToArea } from "./covid19util";

import * as am4core from "@amcharts/amcharts4/core";
import * as am4maps from "@amcharts/amcharts4/maps";
import am4geodata_worldLow from "@amcharts/amcharts4-geodata/worldLow";
import am4geodata_usaLow from "@amcharts/amcharts4-geodata/usaLow";
import am4geodata_chinaLow from "@amcharts/amcharts4-geodata/chinaLow";
import am4geodata_canadaLow from "@amcharts/amcharts4-geodata/canadaLow";
import am4geodata_australiaLow from "@amcharts/amcharts4-geodata/australiaLow";
import am4themes_animated from "@amcharts/amcharts4/themes/animated";

const HEAT_MAP_MIN_COLOR = "#fcbba0";
const HEAT_MAP_MAX_COLOR = "#66000d";
const MAP_HOVER_COLOR = "#e43027";

am4core.useTheme(am4themes_animated);

class Covid19Map extends Component {
  constructor() {
    super();
    this.modelAPI = new ModelAPI();

    this.state = {
      areasList : [],
      showState: false,
      worldSeries: {},
      usaSeries: {},
      chinaSeries:{},
      canadaSeries:{},
      austriliaSeries:{}
    }

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

  onShowState = (value) =>{
    this.setState({
      showState: value
    });
  }

  fetchData(dynamicMapOn) {
    if (!dynamicMapOn || (this.props.confirmed_model === "" && this.props.death_model === "")) {
      //without dynamic map,show to cumulative cases to date
      if (this.props.dataType === "confirmed")
      {
        this.modelAPI.cumulative_infections(cumulativeInfections => {
          let heatmapData = cumulativeInfections.map(d => {
            return {
              id: d.area.iso_2,
              // Adjust all heatmap values by log scale.
              //value: d.value > 0 ? Math.log(d.value) : 0,
              value: Math.log(d.percentage),
              // Store the true value so we can display tooltips correctly.
              valueTrue: d.value,
              area: d.area
            };
          });
          this.setState({ heatmapData }, this.initChart);
        });
      }
      else
      {
        this.modelAPI.cumulative_death({
          days: 0
        },cumulativeDeath => {
          let heatmapData = cumulativeDeath.map(d => {
            return {
              id: d.area.iso_2,
              // Adjust all heatmap values by log scale.
              //value: d.value > 0 ? Math.log(d.value) : 0,
              value:Math.log(d.percentage),
              // Store the true value so we can display tooltips correctly.
              valueTrue: d.value,
              area: d.area
            };
          });
          this.setState({ heatmapData }, this.resetChart);
        });
      }
      
    } else {
      //with dynamic map 
      if (this.props.statistic === "cumulative"){
        if (this.props.days > 0)
        {
          this.modelAPI.predict_all({
            days: this.props.days,
            model: this.props.dataType === "confirmed"?this.props.confirmed_model:this.props.death_model
          }, cumulativeInfections => {
            let heatmapData = cumulativeInfections.map(d => {
              return {
                id: d.area.iso_2,
                // Adjust all heatmap values by log scale.
                // value: d.value > 0 ? Math.log(d.value) : 0,
                value: Math.log(d.percentage),
                // Store the true value so we can display tooltips correctly.
                valueTrue: d.value,
                area: d.area
              };
            });
            this.setState({ heatmapData }, this.resetChart);
          });
        }
        else
        {
          // show history cumulative
            this.modelAPI.history_cumulative({
              days: this.props.days
            }, historyCumulative => {
              let heatmapData = historyCumulative.map(d => {
                if (this.props.dataType === "confirmed")
                {
                  return {
                    id: d.area.iso_2,
                    // Adjust all heatmap values by log scale.
                    // value: d.value > 0 ? Math.log(d.value) : 0,
                    value:Math.log(d.value_percentage),
                    // Store the true value so we can display tooltips correctly.
                    valueTrue: d.value,
                    area: d.area
                  };
                }
                else
                {
                  return {
                    id: d.area.iso_2,
                    // Adjust all heatmap values by log scale.
                    //value: d.deathValue > 0 ? Math.log(d.deathValue) : 0,
                    value: Math.log(d.death_percentage),
                    // Store the true value so we can display tooltips correctly.
                    valueTrue: d.deathValue,
                    area: d.area
                  }
                }
                
              });
              this.setState({ heatmapData }, this.resetChart);
            });

        }
      }
      else
      {
        //new cases
        if (this.props.days>0)
        {
          //prediction
          this.modelAPI.predict_all({
            days: this.props.days,
            model: this.props.dataType === "confirmed"?this.props.confirmed_model:this.props.death_model
          }, cumulativeInfections => {
            //if days is one, we need data from days = 0, which is in history_cumulative
            if (this.props.days > 7)
            {
              this.modelAPI.predict_all({
                days: this.props.days - 7,
                model: this.props.dataType === "confirmed"?this.props.confirmed_model:this.props.death_model
              }, previousCumulative =>{
                let heatmapData = cumulativeInfections.map((d, index) =>{
                  return {
                    id: d.area.iso_2,
                    value: d.value - previousCumulative[index].value > 0 ? Math.log(d.value - previousCumulative[index].value): 0,
                    valueTrue:  d.value - previousCumulative[index].value > 0? d.value - previousCumulative[index].value: 0,
                    area: d.area
                  }
                });
                this.setState({ heatmapData }, this.resetChart);
              });
            }
            else
            {
              this.modelAPI.history_cumulative({
                days: this.props.days - 7
              }, previousCumulative =>{
                let heatmapData = cumulativeInfections.map((d, index) =>{
                  if (this.props.dataType === "confirmed")
                  {
                    return {
                      id: d.area.iso_2,
                      value: d.value - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).value > 0 ? Math.log(d.value - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).value ): 0,
                      valueTrue:  d.value - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).value > 0?
                                  d.value - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).value:0,
                      area: d.area
                    }
                  }
                  else
                  {
                    return {
                      id: d.area.iso_2,
                      value: d.deathValue - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).deathValue > 0 ? Math.log(d.deathValue - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).deathValue ): 0,
                      valueTrue:  d.deathValue - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).deathValue > 0?
                                  d.deathValue - previousCumulative.find(x => x.area.iso_2 === d.area.iso_2).deathValue:0,
                      area: d.area
                    }
                  }
                  
                });
                this.setState({ heatmapData }, this.resetChart);
              });
            }
          });
        }
        else
        {
          //history
          this.modelAPI.history_cumulative({
            days: this.props.days,
          }, historyInfections => {
            this.modelAPI.history_cumulative({
              days: this.props.days - 7,
            }, nextDayCumulative =>{
              let heatmapData = historyInfections.map((d, index) =>{
                if (this.props.dataType === "confirmed")
                {
                  return {
                    id: d.area.iso_2,
                    value: d.value - nextDayCumulative[index].value > 0 ? Math.log(d.value - nextDayCumulative[index].value): 0,
                    valueTrue: d.value - nextDayCumulative[index].value > 0 ? d.value - nextDayCumulative[index].value: 0,
                    area: d.area
                  }
                }
                else
                {
                  return{
                    id: d.area.iso_2,
                    value: d.deathValue - nextDayCumulative[index].deathValue > 0 ? Math.log(d.deathValue - nextDayCumulative[index].deathValue): 0,
                    valueTrue: d.deathValue - nextDayCumulative[index].deathValue > 0 ? d.deathValue - nextDayCumulative[index].deathValue: 0,
                    area: d.area
                  }
                }
                
              });
              this.setState({ heatmapData }, this.resetChart);
            });
          });
        }
      }
      
    }
  }

  initChart() {
    // Create map instance
    this.chart = am4core.create("chartdiv", am4maps.MapChart);
    // Set projection
    this.chart.projection = new am4maps.projections.Mercator();
    let worldSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    worldSeries = this.createChartSeries(worldSeries, {
      geodata: am4geodata_worldLow,
      exclude: ["AQ"],
      data: this.state.heatmapData
    });
    let chinaSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    chinaSeries = this.createChartSeries(chinaSeries, {
      geodata: am4geodata_chinaLow,
      data: this.state.heatmapData,
      disabled: !this.state.showState
    });
    let usaSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    usaSeries = this.createChartSeries(usaSeries, {
      geodata: am4geodata_usaLow,
      data: this.state.heatmapData,
      disabled: !this.state.showState
    });
    let canadaSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    canadaSeries = this.createChartSeries(canadaSeries, {
      geodata: am4geodata_canadaLow,
      data: this.state.heatmapData,
      disabled: !this.state.showState
    });
    let australiaSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
    australiaSeries = this.createChartSeries(australiaSeries, {
      geodata: am4geodata_australiaLow,
      data: this.state.heatmapData,
      disabled: !this.state.showState
    });
    
    this.stateSeries = [usaSeries];
    
    this.initChartInterface();

    this.setState({
      worldSeries,
      chinaSeries,
      usaSeries,
      canadaSeries,
      australiaSeries
    });

  }

  createChartSeries(series, seriesProps) {
    const {statistic} = this.props;
    series = Object.assign(series, seriesProps);

    let polygonTemplate = series.mapPolygons.template;

    // Heatmap fill.
    if (statistic === "cumulative")
    {
      series.heatRules.push({
        property: "fill",
        target: polygonTemplate,
        min: am4core.color(HEAT_MAP_MIN_COLOR),
        max: am4core.color(HEAT_MAP_MAX_COLOR),
        minValue: 0,
        maxValue: Math.log(1000)
      });
    }
    else 
    {
      series.heatRules.push({
        property: "fill",
        target: polygonTemplate,
        min: am4core.color(HEAT_MAP_MIN_COLOR),
        max: am4core.color(HEAT_MAP_MAX_COLOR),
        minValue: 0,
        maxValue: Math.log(1000)
      });
    }
    

    // Configure series tooltip. Display the true value of infections.
    polygonTemplate.tooltipText = "{name}: {valueTrue}";
    polygonTemplate.nonScalingStroke = true;
    polygonTemplate.strokeWidth = 0.5;

    // Create hover state and set alternative fill color.
    let hs = polygonTemplate.states.create("hover");
    hs.properties.fill = am4core.color(MAP_HOVER_COLOR);

    // Change mouse cursor to pointer.
    polygonTemplate.cursorOverStyle = am4core.MouseCursorStyle.pointer;

    // Create click handler. Apparently ALL the series in the chart must have
    // click handlers activated, so if this function is not running double-check
    // that other series also have click handlers.
    const { onMapClick, onNoData} = this.props;
    polygonTemplate.events.on("hit", e => {
      const { id, value, area, name} = e.target.dataItem.dataContext;
      if (area){
        onMapClick(area);
      }
      else
      {
        onNoData(name);
      }
    });

    return series;
  }

  initChartInterface() {
    const {showState} = this.state;
    // Create a zoom control.
    this.chart.zoomControl = new am4maps.ZoomControl();
    this.chart.zoomControl.cursorOverStyle = am4core.MouseCursorStyle.pointer;

    // Create a toggle button to show/hide states/provinces.
    let button = this.chart.chartContainer.createChild(am4core.Button);
    button.label.text = `${
      showState ? "Hide" : "Show"
      } States/Provinces`;
    button.togglable = true;
    button.padding(5, 5, 5, 5);
    button.align = "right";
    button.marginRight = 15;
    button.cursorOverStyle = am4core.MouseCursorStyle.pointer;
    button.events.on("hit", () => {
      this.onShowState(button.isActive);
      const {showState} = this.state;
      this.stateSeries.forEach(s => {
        (s.disabled = !showState);
      });
      button.label.text = `${
        showState ? "Hide" : "Show"
        } States/Provinces`;
    });
  }

  resetChart() {
    let worldSeries = this.state.worldSeries;
    let usaSeries = this.state.usaSeries;
    let chinaSeries = this.state.chinaSeries;
    let canadaSeries = this.state.canadaSeries;
    let australiaSeries = this.state.austriliaSeries;
    worldSeries.data = this.state.heatmapData;
    usaSeries.data = this.state.heatmapData;
    canadaSeries.data = this.state.heatmapData;
    chinaSeries.data = this.state.heatmapData;
    australiaSeries.data = this.state.heatmapData;
  }

  componentWillUnmount() {
    if (this.chart) {
      this.chart.dispose();
    }
  }

  render() {
    
    return <div id="chartdiv"></div>;
  }
}

export default Covid19Map;
