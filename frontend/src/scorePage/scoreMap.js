import React, { Component } from "react";
import { Circle, Map, Marker, Popup, TileLayer } from "react-leaflet";
import ModelAPI from "../modelapi";
import { areaToStr, strToArea } from "../covid19util";

import * as am4core from "@amcharts/amcharts4/core";
import * as am4maps from "@amcharts/amcharts4/maps";
import am4geodata_worldLow from "@amcharts/amcharts4-geodata/worldLow";
import am4geodata_usaLow from "@amcharts/amcharts4-geodata/usaLow";
import am4geodata_chinaLow from "@amcharts/amcharts4-geodata/chinaLow";
import am4geodata_canadaLow from "@amcharts/amcharts4-geodata/canadaLow";
import am4geodata_australiaLow from "@amcharts/amcharts4-geodata/australiaLow";
import am4themes_animated from "@amcharts/amcharts4/themes/animated";

const HEAT_MAP_MIN_COLOR = "#CB7F50";
const HEAT_MAP_MAX_COLOR = "#85DB50";
const MAP_HOVER_COLOR = "#83FE00";

am4core.useTheme(am4themes_animated);

class ScoreMap extends Component {
    constructor() {
      super();
      this.modelAPI = new ModelAPI();
  
      this.state = {
        areasList : [],
        showState: false
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
            this.setState({ heatmapData }, this.createChart);
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
                this.setState({ heatmapData }, this.createChart);
            });
        }
    }

    initChart() {
        // Create map instance
        this.chart = am4core.create("chartdiv", am4maps.MapChart);
        // Set projection
        this.chart.projection = new am4maps.projections.Mercator();
    }

    createChartSeries(seriesProps) {
        const {statistic} = this.props;
        // Create new map polygon series and copy over all given props.
        let series = this.chart.series.push(new am4maps.MapPolygonSeries());
        series = Object.assign(series, seriesProps);
    
        let polygonTemplate = series.mapPolygons.template;
    
      
        series.heatRules.push({
            property: "fill",
            target: polygonTemplate,
            min: am4core.color(HEAT_MAP_MIN_COLOR),
            max: am4core.color(HEAT_MAP_MAX_COLOR),
        });

        
        // Configure series tooltip. Display the true value of infections.
        polygonTemplate.tooltipText = "{name}: {value} (conf: {conf})";
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
    
      createChart() {
        const { heatmapData } = this.state;
    
        this.initChart();
    
        const worldSeries = this.createChartSeries({
          geodata: am4geodata_worldLow,
          exclude: ["AQ"],
          data: heatmapData
        });
    
        // const chinaSeries = this.createChartSeries({
        //   geodata: am4geodata_chinaLow,
        //   data: heatmapData,
        //   disabled: !this.state.showState
        // });
    
        const usaSeries = this.createChartSeries({
          geodata: am4geodata_usaLow,
          data: heatmapData,
          disabled: !this.state.showState
        });
    
        // const canadaSeries = this.createChartSeries({
        //   geodata: am4geodata_canadaLow,
        //   data: heatmapData,
        //   disabled: !this.state.showState
        // });
    
        // const australiaSeries = this.createChartSeries({
        //   geodata: am4geodata_australiaLow,
        //   data: heatmapData,
        //   disabled: !this.state.showState
        // });
    
        //this.stateSeries = [chinaSeries, usaSeries, canadaSeries, australiaSeries];
        this.stateSeries = [usaSeries]
    
        this.initChartInterface();
      }
    
      resetChart() {
        const { heatmapData } = this.state;
    
        const worldSeries = this.createChartSeries({
          geodata: am4geodata_worldLow,
          exclude: ["AQ"],
          data: heatmapData
        });
    
        const usaSeries = this.createChartSeries({
          geodata: am4geodata_usaLow,
          data: heatmapData,
          disabled: !this.state.showState
        });
    
        this.stateSeries = [usaSeries];
    
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