import React, { Component } from "react";
import { Circle, Map, Marker, Popup, TileLayer } from "react-leaflet";
import ModelAPI from "../modelapi";
import { areaToStr, strToArea } from "../covid19util";

import * as am4core from "@amcharts/amcharts4/core";
import * as am4maps from "@amcharts/amcharts4/maps";
import am4geodata_worldLow from "@amcharts/amcharts4-geodata/worldLow";
import am4geodata_usaLow from "@amcharts/amcharts4-geodata/usaLow";
import am4themes_animated from "@amcharts/amcharts4/themes/animated";

const HEAT_MAP_MIN_COLOR = "#85DB50";
const HEAT_MAP_MAX_COLOR = "#F33A21";
const MAP_HOVER_COLOR = "#83FE00";

am4core.useTheme(am4themes_animated);

class ScoreMap extends Component {
    constructor() {
      super();
      this.modelAPI = new ModelAPI();
  
      this.state = {
        areasList : [],
        showState: false,
        worldSeries: {},
        usaSeries: {}
      }
  
      this.modelAPI.areas(allAreas =>
        this.setState({
          areasList: allAreas
        })
      );
    }

    componentDidMount() {
        this.props.triggerRef(this);
    }

    onShowState = (value) =>{
        this.setState({
          showState: value
        });
    }

    fetchData(dynamicMapOn)
    {
        if (!dynamicMapOn) {
          //without dynamic map,show to latestscore
          this.modelAPI.scores_all(
            {
                weeks: this.props.latestWeek,
            } , scores => {
              let heatmapData = scores.map(d => {
              return {
                id: d.area.iso_2,
                value: d.value > 0 ? d.value: 0,
                area: d.area,
                conf: d.conf
              };
            });
            this.setState({ heatmapData }, this.initChart);
          });
        } else {
            this.modelAPI.scores_all(
            {
                weeks: this.props.weeks,
            }, scores =>{
            let heatmapData = scores.map(d => {
                return {
                    id: d.area.iso_2,
                    value: d.value > 0 ? d.value: 0,
                    area: d.area
                };
                });
                this.setState({ heatmapData }, this.updateChart);
            });
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
        let usaSeries = this.chart.series.push(new am4maps.MapPolygonSeries());
        usaSeries = this.createChartSeries(usaSeries, {
          geodata: am4geodata_usaLow,
          data: this.state.heatmapData,
          disabled: !this.state.showState
        });
        this.stateSeries = [usaSeries];
        this.initChartInterface();
        this.setState({
          worldSeries,
          usaSeries
        });
    }

    updateChart(){
      let worldSeries = this.state.worldSeries;
      let usaSeries = this.state.usaSeries;
      worldSeries.data = this.state.heatmapData;
      usaSeries.data = this.state.heatmapData;
    }

    createChartSeries(series, seriesProps) {
        series = Object.assign(series, seriesProps);
        let polygonTemplate = series.mapPolygons.template;
        series.heatRules.push({
            property: "fill",
            target: polygonTemplate,
            min: am4core.color(HEAT_MAP_MIN_COLOR),
            max: am4core.color(HEAT_MAP_MAX_COLOR),
            minValue: 0,
            maxValue: 4
        });
        
        // Configure series tooltip. Display the true value of infections.
        polygonTemplate.tooltipText = "{name}: {value}";
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
        // Create a zoom control.
        const {showState} = this.state;
        this.chart.zoomControl = new am4maps.ZoomControl();
        this.chart.zoomControl.cursorOverStyle = am4core.MouseCursorStyle.pointer;
    
        // Create a toggle button to show/hide states/provinces.
        let button = this.chart.chartContainer.createChild(am4core.Button);
        //button.label.text = "Show States/Provinces";
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
          this.stateSeries.forEach(s => (s.disabled = !showState));
          button.label.text = `${
            showState ? "Hide" : "Show"
            } States/Provinces`;
        });
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

export default ScoreMap;