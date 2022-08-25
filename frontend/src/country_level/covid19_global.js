import React, { Component } from "react";
import Papa from "papaparse";
import 'antd/dist/antd.css';
import "./covid19_global.css";
import { ResponsiveLine } from "@nivo/line";
//import moment from "moment";
import numeral from "numeral";
import ReactGA from "react-ga";

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
  Input
} from "antd";

var g_cases = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/global_data.csv";
var g_deaths = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/global_deaths.csv";
var g_case_preds = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/global_forecasts_current_0.csv";
var g_death_preds = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/global_deaths_current_0.csv";
var globallist = [];
const init_areas = "US";
const { Option } = Select;

class Covid19_global extends Component {

	constructor() {
		super();
		this.state = {
      area_message: "Please wait for data to load",
      cum_or_inc: "Cumulative",
      data_loading: true,
      areas: init_areas,
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
    this.doneLoading = this.doneLoading.bind(this);
    this.addNewArea = this.addNewArea.bind(this);

  }

  componentDidMount() {
    this.updateWindowDimensions();
    window.addEventListener('resize', this.updateWindowDimensions);
    ReactGA.initialize('UA-186385643-1');
    ReactGA.pageview('/ReCOVER/RoW');
    this.setState({arealist: globallist});
  }

  componentWillMount() {

    Papa.parse(g_cases, {
      download: true, worker: true,
      complete: function(results) {
        var i;
          //var globallist = [];
          for(i=1; i<results.data.length; i++)
          {
            if(results.data[i].length > 2){
              globallist[i-1] = results.data[i][1];
            }
          }
          this.setState({data_date: results.data[0].slice(2).map(y=>y.concat('T23:00:00Z'))});
          this.setState({arealist: globallist});
          this.setState({case_data: results.data}, ()=>{this.doneLoading()});
          //console.log(this.state.data_date);
        }.bind(this)
      });

    Papa.parse(g_deaths, {
      download: true, worker: true,
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
        this.setState({death_data: results.data}, ()=>{this.doneLoading()});
      }.bind(this)
    });

    Papa.parse(g_case_preds, {
      download: true, worker: true,
      complete: function(results) {
        var i;
        var thislist = [];
        for(i=1; i<results.data.length; i++)
        {
          if(results.data[i].length > 2){
            thislist[i-1] = results.data[i][1];
          }
        }
        this.setState({pred_date: results.data[0].slice(2).map(y=>y.concat('T23:00:00Z'))});
        this.setState({case_pred_list: thislist});
        this.setState({case_preds: results.data}, ()=>{this.doneLoading()});
        //console.log(this.state.pred_date);
      }.bind(this)
    });

    Papa.parse(g_death_preds, {
      download: true, worker: true,
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
        this.setState({death_preds: results.data}, ()=>{this.doneLoading()});
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

    if(this.state.cum_or_inc === "Cumulative")
    {  
      for(i=0; i<thisdata.length; i++)
      {
        if(thisdata[i] > 0 && this.state.data_date[i]){
          dd.push({
            x: this.state.data_date[i],
            y: thisdata[i]
          });
        }
      }
      var dd_p = [];
      for(i=0; i<preds.length; i++)
      {
        if (this.state.pred_date[i])
        {
        dd_p.push({
          x: this.state.pred_date[i],
          y: preds[i]
        });
      }
      }
    }
    else
    {
      var base_dat = thisdata[0];
      var diff_dat = 0;
      for(i=1; i<thisdata.length; i++)
      {
        diff_dat = thisdata[i] -base_dat;
        if(diff_dat >= 0 && base_dat> 0 && this.state.data_date[i])
        {
          dd.push({
            x: this.state.data_date[i],
            y: diff_dat
          });
        }
        base_dat = thisdata[i];
      }
      var dd_p = [];
      base_dat = thisdata[thisdata.length-1];
      //base_dat = base_dat>0?base_dat:-1;
      for(i=0; i<preds.length; i++)
      {
        diff_dat = preds[i] -base_dat;
        if(diff_dat >= 0 && base_dat> 0 && this.state.pred_date[i])
        {
          dd_p.push({
            x: this.state.pred_date[i],
            y: diff_dat
          });
        }
        base_dat = preds[i];
      }
    }
    var full_dd = [{id: "Data", data:dd}, {id: "Forecasts", data:dd_p},];
    this.setState({to_plot: full_dd});
    //console.log(full_dd);
  }

  addNewArea(areas)
  {
      var idx = this.state.arealist.indexOf(areas);
      var case_d = [];
      //console.log(idx);
      if (idx>-1){
        case_d = this.state.case_data[idx+1].slice(2);
      }
      this.setState({case_data_plot : case_d});

      case_d = [];
      idx = this.state.case_pred_list.indexOf(areas);
      if (idx>-1){
        case_d = this.state.case_preds[idx+1].slice(2);
      }
      this.setState({case_preds_plot : case_d});
      
      var death_d = [];
      idx = this.state.death_list.indexOf(areas);
      if (idx>-1){
        death_d = this.state.death_data[idx+1].slice(2);
      }
      this.setState({death_data_plot : death_d});
      
      death_d =[];
      idx = this.state.death_pred_list.indexOf(areas);
      if (idx>-1){
        death_d = this.state.death_preds[idx+1].slice(2);
      }
      this.setState({death_preds_plot: death_d}, ()=>{this.plotData()});
  }

  onValuesChange(changedValues, allValues){

    if ("areas" in changedValues)
    {
      this.addNewArea(allValues.areas);
    }
    if("cum_or_inc" in changedValues)
    {
      this.setState({cum_or_inc: allValues.cum_or_inc}, ()=>this.plotData());  
    }
    this.setState({CoD: allValues.CoD}, ()=>this.plotData());
  }

  doneLoading()
  {
      if(this.state.data_loading & this.state.case_preds.length>0 && this.state.death_preds.length>0 && this.state.death_data.length > 0 && this.state.case_data.length > 0)
      {
        this.setState({data_loading: false});
        this.setState({area_message: "Start typing a location name to see its data and forecasts"});
        this.setState({areas: init_areas}, ()=>{this.addNewArea(this.state.areas)});
      }
  }

  render() {
    const {areas,arealist,CoD, to_plot, data_loading, cum_or_inc, area_message} = this.state;
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
       <div style={{color: "#1f1c1c"}}>
       <div className="grid">
         <div className = "introduction">
         <Row>
         <h1>COVID19 Forecasts for Countries around the World</h1>
         </Row>
         <div style ={{background: "#fae3a2"}}>
         <Row>
         <p>
         Note: These forecasts are generated through automated scripts and not analyzed or fixed manually. 
         </p>
         </Row>
         <Row>
         <p>
         Note: Unreliable forecasts expected due to uncertain case reporting. 
         </p>
         
         </Row>
         </div> 
         </div>

         <Row>
         <div className="form-column-row">
         
         <Form 
         ref={this.formRef}
         onValuesChange={this.onValuesChange}
         initialValues={{
          areas: areas,
          CoD: CoD,
          cum_or_inc: cum_or_inc,
        }}>

       
        <Popover
        content={area_message}
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
          loading = {this.state.data_loading}
          style={{ width: "100%" }}
          placeholder="Select Areas"
          >
          {optionlist}
          </Select>
          </Form.Item>
          </Popover>
          
          
            <Row>

            <Col>
            <Popover
            content={"Choose to plot cumulative or new weekly numbers"}
            placement="bottomLeft">

            <Form.Item label="Data Type" style={{marginBottom: "5px"}} name="cum_or_inc" value={cum_or_inc}>
            <Radio.Group
            initialValue = "Cumulative"
            buttonStyle="solid"
            >
            <Radio.Button value="Cumulative">Cumulative</Radio.Button>
            <Radio.Button value="New">Weekly New</Radio.Button>
            </Radio.Group>
            </Form.Item>
            </Popover>
            </Col>

            <Col>
            <Popover
            content={"Choose cases or deaths to plot"}
            placement="bottomLeft">

            <Form.Item label="" style={{marginBottom: "5px"}} name="CoD" value={CoD}>
            <Radio.Group
            initialValue = "case"
            buttonStyle="solid"
            >
            <Radio.Button value="case">Cases</Radio.Button>
            <Radio.Button value="death">Deaths</Radio.Button>
            </Radio.Group>
            </Form.Item>
            </Popover>
            </Col>

            </Row>
          </Form>
          </div>
          </Row>
          <Row>
          <div className="graph-row">
            <ResponsiveLine
            data = {to_plot}
            margin={{ top: 50, right: 10, bottom: 100, left: 60 }}
            xScale={{
              type: "time",
              format: "%Y-%m-%dT%H:%M:%SZ",
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
              legend: cum_or_inc.concat(' '.concat(CoD.concat('s'))),
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
            </div>
          </Row>


          </div>
          </div>
          );
        }
      }

      export default Covid19_global;