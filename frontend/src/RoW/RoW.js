import React, { Component } from "react";
import Papa from "papaparse";
import 'antd/dist/antd.css';
import "./RoW.css";
import { ResponsiveLine } from "@nivo/line";
import moment from "moment";
import numeral from "numeral";

import {
  List,
  Form,
  Select,
  InputNumber,
  Button,
  Radio,
  Checkbox,
  Slider,
  Tooltip,
  Switch,
  Popover,
  Alert,
  Row,
  Col,
} from "antd";

var g_cases = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/google_data.csv";
var g_deaths = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/google_deaths.csv";
var g_case_preds = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/google_forecasts_current_0.csv";
var g_death_preds = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/google_deaths_current_0.csv";
var globallist = [];

const { Option } = Select;

class RoW extends Component {

	constructor() {
		super();
		this.state = {
      areas: [],
      width: 0, 
      height: 0,
      arealist: [],
      case_data: [],
      death_data: [],
      death_list:[],
      case_preds: [],
      case_pred_list: [],
      death_preds: [],
      death_pred_list: [],
      CoD: "case",
      case_data_plot: [],
      death_data_plot: [],
      case_preds_plot: [],
      death_preds_plot: [],
      data_date:[],
      pred_date: [],
      to_plot: []
    };


    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
    this.plotData = this.plotData.bind(this);
    this.onValuesChange = this.onValuesChange.bind(this);
    

  }

  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);

    this.setState({arealist: globallist});
  }

  componentWillMount() {

    Papa.parse(g_cases, {
      download: true,
      complete: function(results) {
        var i;
          //var globallist = [];
          for(i=1; i<results.data.length; i++)
          {
            if(results.data[i].length > 2){
              globallist[i-1] = results.data[i][1];
            }
          }
          this.setState({data_date: results.data[0].slice(2)});
          this.setState({arealist: globallist});
          this.setState({case_data: results.data});
          //console.log(this.state.data_date);
        }.bind(this)
      });

    Papa.parse(g_deaths, {
      download: true,
      complete: function(results) {
        var i;
        var thislist = [];
        for(i=1; i<results.data.length; i++)
        {
          if(results.data[i].length > 2){
            thislist[i-1] = results.data[i][1];
          }
        }
        this.setState({death_list: thislist});
        this.setState({death_data: results.data});
      }.bind(this)
    });

    Papa.parse(g_case_preds, {
      download: true,
      complete: function(results) {
        var i;
        var thislist = [];
        for(i=1; i<results.data.length; i++)
        {
          if(results.data[i].length > 2){
            thislist[i-1] = results.data[i][1];
          }
        }
        this.setState({pred_date: results.data[0].slice(2)});
        this.setState({case_pred_list: thislist});
        this.setState({case_preds: results.data});
        //console.log(this.state.pred_date);
      }.bind(this)
    });

    Papa.parse(g_death_preds, {
      download: true,
      complete: function(results) {
        var i;
        var thislist = [];
        for(i=1; i<results.data.length; i++)
        {
          if(results.data[i].length > 2){
            thislist[i-1] = results.data[i][1];
          }
        }
        this.setState({death_pred_list: thislist});
        this.setState({death_preds: results.data});
        //console.log(this.state.death_preds.length);
      }.bind(this)
    });
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateWindowDimensions);
  }

  updateWindowDimensions() {
    this.setState({ width: window.innerWidth, height: window.innerHeight });
  }

  plotData()
  {
    var dd=[];
    var thisdata, preds;
    var i;

    if(this.state.CoD === "case")
    {
      thisdata = this.state.case_data_plot;
      preds = this.state.case_preds_plot;
    }
    else
    {
      thisdata = this.state.death_data_plot;
      preds = this.state.death_preds_plot; 
    }

    for(i=0; i<thisdata.length; i++)
    {
      if(thisdata[i] > 0){
      dd.push({
        x: this.state.data_date[i],
        y: thisdata[i]
      });
      }
    }
    var dd_p = [];
    for(i=0; i<preds.length; i++)
    {
      dd_p.push({
        x: this.state.pred_date[i],
        y: preds[i]
      });
    }

    var full_dd = [{id: "Data", data:dd}, {id: "Forecasts", data:dd_p},];
    this.setState({to_plot: full_dd});
    //console.log(full_dd);
  }

  onValuesChange(changedValues, allValues){

    if ("areas" in changedValues)
    {
      var idx = this.state.arealist.indexOf(allValues.areas);
      var case_d = [];
      //console.log(idx);
      if (idx>-1){
        case_d = this.state.case_data[idx+1].slice(2);
      }
      this.setState({case_data_plot : case_d});

      case_d = [];
      idx = this.state.case_pred_list.indexOf(allValues.areas);
      if (idx>-1){
        case_d = this.state.case_preds[idx+1].slice(2);
      }
      this.setState({case_preds_plot : case_d});
      
      var death_d = [];
      idx = this.state.death_list.indexOf(allValues.areas);
      if (idx>-1){
        death_d = this.state.death_data[idx+1].slice(2);
      }
      this.setState({death_data_plot : death_d});
      
      death_d =[];
      idx = this.state.death_pred_list.indexOf(allValues.areas);
      if (idx>-1){
        death_d = this.state.death_preds[idx+1].slice(2);
      }
      this.setState({death_preds_plot: death_d});
    }
    this.setState({CoD: allValues.CoD}, ()=>this.plotData());
  }



  render() {
    const {areas,arealist,CoD, to_plot} = this.state;
    //console.log(to_plot);
    const theme = {
      axis: {
        ticks: {
          text: {
            fontSize: 16
          }
        },
        legend: {
          text: {
            fontSize: 16
          }
        }
      },
      legends: {
        text: {
          fontSize: 16
        }
      }
    };
    let optionlist = arealist.length > 0
    && arealist.map ((s) => {
      return (
        <Option key={s} value={s}>{s}</Option>
        )
      }, this);
      const num_ticks = 1 + this.state.width/280;
      
      return (
       <div className="page-wrapper">
       <div className="grid">
       <Row>
       <h1>Forecasts for "Almost" Everywhere</h1>
       </Row>

       <Row>
       <div className = "introduction"><p>
       Use this page to see forecasts not addressed on the main page. Forecasts are available for all locations (around 18,000) for which Google makes its data 
       <a href="https://github.com/scc-usc/covid19-forecast-bench"> public</a>. 
       </p>
       </div>

       </Row> 
       <Row>
       <div className="form-column">
       <Form 
       ref={this.formRef}
       onValuesChange={this.onValuesChange}
       initialValues={{
        areas: areas,
        CoD: CoD,
      }}>
      <Popover
      content={"start typing a location name to plot its data."}
      placement="top"
      >
      <Form.Item
      style={{ marginBottom: "0px" }}
      label="Location"
      name="areas"
      rules={[
        { required: true, message: "Please select areas!" },
        ]}
        >
        <Select
        showSearch
        style={{ width: "100%" }}
        placeholder="Select Areas"
        >
        {optionlist}
        </Select>
        </Form.Item>
        </Popover>

        <Popover
        content={"Choose cases or deaths to plot"}
        placement="bottomLeft"

        >
        <Form.Item label="Data Type" style={{marginBottom: "5px"}} name="CoD" value={CoD}>
        <Radio.Group
        initialValue = "case"
        buttonStyle="solid"
        >
        <Radio.Button value="case">Cases</Radio.Button>
        <Radio.Button value="death">Deaths</Radio.Button>
        </Radio.Group>
        </Form.Item>
        </Popover>

        </Form>
        </div>
        </Row>

        <div className="graph">
        <ResponsiveLine
        data = {to_plot}
        margin={{ top: 50, right: 10, bottom: 100, left: 60 }}
        xScale={{
          type: "time",
          format: "%Y-%m-%d",
        }}
        xFormat="time:%Y-%m-%d"
        yScale={{
          type: "linear",
          min: "auto",
          max: "auto",
          stacked: false,
          reverse: false
        }}
        axisTop={null}
        axisRight={null}
        axisLeft={{
          format: y => numeral(y).format("0.[0]a"),
          orient: "left",
          tickSize: 5,
          tickPadding: 5,
          tickRotation: 0,
          legend: CoD.concat('s'),
          legendOffset: -55,
          legendPosition: "middle",
        }}
        axisBottom={{
          format: "%b %d",
          tickValues: num_ticks,
          legend: "date",
          legendOffset: 36,
          legendPosition: "middle"
        }}
        colors={{ scheme: "nivo" }}
        pointSize={10}
        pointColor={{ theme: "background" }}
        pointBorderWidth={2}
        pointBorderColor={{ from: "serieColor" }}
        pointLabel="y"
        pointLabelYOffset={-12}
        useMesh={true}
        legends={[
          {
            text: {fontSize: 14},
            anchor: "top-left",
            direction: "column",
            justify: false,
            translateX: 30,
            translateY: 0,
            itemsSpacing: 0,
            itemDirection: "left-to-right",
            itemWidth: 80,
            itemHeight: 20,
            itemOpacity: 0.75,
            symbolSize: 12,
            symbolShape: "circle",
            symbolBorderColor: "rgba(0, 0, 0, .5)",
            effects: [
            {
              on: "hover",
              style: {
                itemBackground: "rgba(0, 0, 0, .03)",
                itemOpacity: 1
              }
            }
            ]
          }
          ]}
          theme = {theme}
          />
          <Row>
          <div className = "introduction">
          Click on the following links to download CSV files to analyze yourself: {"\n"}
          <ul>
          <li><a href =  "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/google_data.csv" download>
          All formatted case data from Google </a></li>
          <li><a href =  "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/google_deaths.csv" download>
          All formatted death data from Google </a> </li>
          <li><a href =  "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/google_forecasts_current_0.csv" download>
          Case forecasts on Google data </a> </li>
          <li><a href =  "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/google_deaths_current_0.csv" download>
          Death forecasts on Google data </a> </li>
          </ul>
          </div>
          </Row>
          <Row>
          <div className = "introduction">
          The following are the latest forecasts for Countries and the US states used on the main forecast page. These files are based on the 
          <a href = "https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data">
          JHU data</a>
          <ul>
          <li><a href =  "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/us_data.csv" download>
          All formatted case data from Google </a></li>
          <li><a href =  "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/us_deaths.csv" download>
          All formatted death data from Google </a></li>
          <li><a href =  "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/global_forecasts_current_0.csv" download>
          Case forecasts on Google data </a></li>
          <li><a href =  "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/global_deaths_current_0.csv" download>
          Death forecasts on Google data </a></li>
          </ul>
          </div>
          </Row>

          </div>
          </div>

          </div>
          );
        }
      }

      export default RoW;