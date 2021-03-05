import React, { Component } from "react";
import Iframe from 'react-iframe';
import "../covid19app.css";
import "./scenarios.css";
import "../RoW/RoW.css";
import ReactGA from "react-ga";
import Papa from "papaparse";
import 'antd/dist/antd.css';
import { ResponsiveLine } from "@nivo/line";
//import moment from "moment";
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
  Input
} from "antd";

const cases_url = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/G_recent_cases.csv";
const vacc_url = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/G_vacc_person.csv";
const vacc_full_url = "https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/G_vacc_full.csv";


const { Option } = Select;



const url_page = "https://htmlpreview.github.io/?https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/frontend/src/scenarios/scenario_plots.html";

function zeros_init(dimensions) {
    var array = [];

    for (var i = 0; i < dimensions[0]; ++i) {
        array.push(dimensions.length == 1 ? 0 : zeros_init(dimensions.slice(1)));
    }

    return array;
}

class Scenarios extends Component {

	constructor() {
		super();
		this.state = {
			area_message: "Please wait for data to load",
			recent_data: [],
			vacc_one: [],
			vacc_full: [],
			done_loading: false,
	      underrep: 1,
	      norm_fact: 1,
	      eff_vacc_full: 0.95,
	      eff_vacc_one: 0.50,
	      data_loading: true,
	      areas: "United States of America|||",
	      width: 0, 
	      height: 0,
	      arealist: [],
	      vacc_one_arealist: [],
	      vacc_full_arealist: [],
	      case_area_list: [],
	      case_data: [],
	      case_data_plot: [],
	      all_data: [],
	      data_date:[],
	      pred_date: [],
	      perc: "0",
	      to_plot: []
			};
  			this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
  			this.doneLoading = this.doneLoading.bind(this);
  			this.onValuesChange = this.onValuesChange.bind(this);
  			this.addNewArea = this.addNewArea.bind(this);
	}

	componentDidMount() {
  		this.updateWindowDimensions();
  		window.addEventListener('resize', this.updateWindowDimensions);
    	ReactGA.initialize('UA-186385643-1');
   	    ReactGA.pageview('/ReCOVER/scenarios');

 	Papa.parse(cases_url, {
      download: true, worker: true,
      complete: function(results) {
      		
      	if(results){
          	this.setState({recent_data: results.data}, ()=>{this.doneLoading()});
      	}
        }.bind(this)
      });


    Papa.parse(vacc_url, {
      download: true, worker: true,
      complete: function(results) {
      	if(results){
          	this.setState({vacc_one: results.data}, ()=>{this.doneLoading()});          
      	}
      }.bind(this)
    });

    Papa.parse(vacc_full_url, {
      download: true, worker: true,
      complete: function(results) {
      	if(results){
          	this.setState({vacc_full: results.data}, ()=>{this.doneLoading()});   
      	}
      }.bind(this)
    });

	}

	componentWillUnmount() {
  		window.removeEventListener('resize', this.updateWindowDimensions);
	}

	updateWindowDimensions() {
  		this.setState({ width: window.innerWidth, height: window.innerHeight });
	}

	clean_area_list(arealist)
	{
		arealist = arealist.sort();
		arealist = arealist.filter(function(el){return (el!=null && el!="");});
		this.setState({arealist:arealist});
	}
	doneLoading()
    {
     if(this.state.recent_data.length > 0 && this.state.vacc_one.length > 0 && this.state.vacc_full.length > 0 && !this.state.done_loading)
      {
      	var arealist = [];
      	var i;
      	for(i=1; i<this.state.recent_data.length; i++)
      	{
      		arealist[i] = this.state.recent_data[i][1];
      	}
      	this.setState({case_area_list: arealist});

		arealist = [];
		var raw_arealist = [];
      	for(i=1; i<this.state.vacc_one.length; i++)
      	{
      		if(this.state.vacc_one[i][1]){
      			arealist[i] =this.state.vacc_one[i][1];
      			raw_arealist[i] =this.state.vacc_one[i][1];
      		}
      	}
      	
      	this.setState({vacc_one_arealist: arealist}, this.clean_area_list(raw_arealist));


      	arealist = [];
      	for(i=1; i<this.state.vacc_full.length; i++)
      	{
      		arealist[i] = this.state.vacc_full[i][1];
      	}
      	this.setState({vacc_full_arealist: arealist});
      	
      	//console.log(merged_data);
      	this.setState({done_loading: true});
      	this.setState({data_loading: false});
      	this.setState({area_message: "Start typing a location name to see its data on vaccination and immunity"}, ()=>{this.addNewArea(this.state.areas)});
      	
      }
  	}

  	addNewArea(areas)
  	{
  		var dd_one = [], dd_full = [], dd_cases = [], dd_imm = [];
  		var vacc_one_idx = this.state.vacc_one_arealist.indexOf(areas);
  		var vacc_full_idx = this.state.vacc_full_arealist.indexOf(areas);
  		var case_idx = this.state.case_area_list.indexOf(areas);

  		const num_dates = this.state.vacc_one[0].length - 3; // subtract 3 columns 
  		const all_dates = this.state.vacc_one[0].slice(2, 2+num_dates).map(y=>y.concat('T23:00:00Z'));
  		//console.log(all_dates);
  		const norm_fact = this.state.perc==="1"? this.state.vacc_one[vacc_one_idx].slice(-1)/100 : 1;
  		this.setState({norm_fact: norm_fact});
  		var all_dat = zeros_init([3, num_dates]);
  		if(vacc_one_idx>-1)
  		{
  			all_dat[0] = (this.state.vacc_one[vacc_one_idx].slice(2, 2+num_dates));
  		}
  		if(vacc_full_idx > -1)
  		{
  			all_dat[1] = (this.state.vacc_full[vacc_full_idx].slice(2, 2+num_dates));
  		}
  		if(case_idx > -1)
  		{
  			all_dat[2] = (this.state.recent_data[case_idx].slice(2, 2+num_dates));
  		}
  		var i;
  		for(i=0; i<num_dates; i++)
  		{
  			dd_one.push({x:all_dates[i], y:all_dat[0][i]/norm_fact});
  			dd_full.push({x:all_dates[i], y:all_dat[1][i]/norm_fact});
  			dd_cases.push({x:all_dates[i], y:all_dat[2][i]/norm_fact});
  			var yy = this.state.eff_vacc_one*(all_dat[0][i] - all_dat[1][i]) + (this.state.eff_vacc_full)*all_dat[1][i] + this.state.underrep*all_dat[2][i];
  			dd_imm.push({x:all_dates[i], y: yy/norm_fact});
  		}	
  		this.setState({data_date: all_dates});
  		this.setState({all_data: all_dat});
  		this.setState({thispopu: this.state.vacc_one[vacc_one_idx].slice(-1)});
  		var full_dd = [{id: "Cases", data:dd_cases}, {id: "People Vaccinated (at least 1 dose)", data:dd_one}, {id:"Full Doses", data:dd_full},{id:"Immunity", data: dd_imm}];
  		this.setState({to_plot: full_dd});
  	}

  	onValuesChange(changedValues, allValues)
  	{
  		var dd_one = [], dd_full = [], dd_cases = [], dd_imm = [];
  		if ("areas" in changedValues)
  		{
  			this.addNewArea(allValues.areas);
  		}

  		else
  		{
  			var all_dat = this.state.all_data;
  			var all_dates = this.state.data_date;
  			var norm_fact = allValues.perc==="1"? this.state.thispopu/100 : 1;
  			var i;

  		for(i=0; i<all_dates.length; i++)
  		{
  			dd_one.push({x:all_dates[i], y:all_dat[0][i]/norm_fact});
  			dd_full.push({x:all_dates[i], y:all_dat[1][i]/norm_fact});
  			dd_cases.push({x:all_dates[i], y:all_dat[2][i]/norm_fact});
  			var yy = (allValues.eff_vacc_one)*(all_dat[0][i] - all_dat[1][i]) + (allValues.eff_vacc_full)*all_dat[1][i] + allValues.underrep*all_dat[2][i];
  			dd_imm.push({x:all_dates[i], y: yy/norm_fact});
  		}	
  		this.setState({data_date: all_dates});
  		this.setState({eff_vacc_one: allValues.eff_vacc_one});
  		this.setState({eff_vacc_full: allValues.eff_vacc_full});
  		this.setState({perc: allValues.perc});
  		this.setState({underrep: allValues.underrep});
  		this.setState({norm_fact:norm_fact});
  		var full_dd = [{id: "Cases", data:dd_cases}, {id: "People Vaccinated (at least 1 dose)", data:dd_one}, {id:"Full Doses", data:dd_full},{id:"Immunity", data: dd_imm}];
  		this.setState({to_plot: full_dd});
  		}
  	}

    render() {

    	const {areas,arealist, to_plot, data_loading, area_message, underrep, eff_vacc_one, eff_vacc_full, perc} = this.state;
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

      const ystring = (this.state.perc==="0")?"Total":"% Population";
      
    	
        return (
            <div className="page-wrapper">
            <div className="grid">
            <Row>
            {<h1>Vaccination Data and Immunity Analysis</h1>}
            </Row>
            
            <Row>


         <div className="form-column-row">
         
         <Form 
         ref={this.formRef}
         onValuesChange={this.onValuesChange}
         initialValues={{
          areas: areas,
		  underrep: underrep,
      		eff_vacc_full:eff_vacc_full,
      		eff_vacc_one: eff_vacc_one,    
      		perc: perc      
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

          <Popover
            content={"Choose to show raw values or percentage by population"}
            placement="bottomLeft">

            <Form.Item label="" name="perc" style={{marginBottom: "0px"}} value={perc}>
            <Radio.Group
            initialValue = "0"
            buttonStyle="solid"
            >
            <Radio.Button value="0">Raw values</Radio.Button>
            <Radio.Button value="1">Percent Population</Radio.Button>
            </Radio.Group>
            </Form.Item>
          </Popover>

          <Popover
            content={"Drag to declare the efficacy of a single dose"}
            placement="bottomLeft">
       		<Row>
       		<Col span={16}>
            <Form.Item label="Single Dose Efficacy" style={{marginBottom: "0px"}} name="eff_vacc_one" value={eff_vacc_one}>
            <Slider
            min={0}
            max={1}
            step = {0.01}
            value = {eff_vacc_one}
            onChange={this.onChange}
          />
           
            </Form.Item>
            </Col>
            <Col>
             <InputNumber
            min={0}
            max={1}
            step = {0.01}
            value = {eff_vacc_one}
            onChange={this.onChange}
            readOnly = {true}
            />
            </Col>
            </Row>
          </Popover>

          <Popover
            content={"Drag to declare the efficacy of a full dose"}
            placement="bottomLeft">
            <Row>
       		<Col span={16}>
            <Form.Item label="Full Dose Efficacy" style={{marginBottom: "0px"}} name="eff_vacc_full" value={eff_vacc_full}>
            <Slider
            min={0}
            max={1}
            step = {0.01}
            value = {eff_vacc_full}
            onChange={this.onChange}
          />
            </Form.Item>
            </Col>
            <Col>
             <InputNumber
            min={0}
            max={1}
            step = {0.01}
            value = {eff_vacc_full}
            onChange={this.onChange}
            readOnly = {true}
            />
            </Col>

            </Row>
          </Popover>

          <Popover
            content={"Drag to declare the ratio of true infections to the reported cases"}
            placement="bottomLeft">
            <Row>
            <Col span={16}>
            <Form.Item label="True Cases/Reported Case" style={{marginBottom: "0px"}} name="underrep" value={underrep}>
            <Slider
            min={1}
            max={10}
            step = {0.1}
            value = {underrep}
            onChange={this.onChange}
          />
            </Form.Item>
            </Col>
            <Col>
             <InputNumber
            min={1}
            max={10}
            step = {0.1}
            value = {underrep}
            onChange={this.onChange}
            readOnly = {true}
            />
            </Col>
            </Row>

          </Popover>
          </Form>
          </div>
            </Row>


            <Row>
          <div className="graph-row">
            <ResponsiveLine
            data = {to_plot}
            margin={{ top: 50, right: 10, bottom: 100, left: 70 }}
            xScale={{
              type: "time",
              format: "%Y-%m-%dT%H:%M:%SZ",
            }}
            xFormat="time:%Y-%m-%d"
            yFormat=".2f"
            
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
              legend: ystring,
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
            //useMesh={true}
            enableSlices = "x"
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
          <Row>
          Vaccine Data Sources: <a href="https://github.com/GoogleCloudPlatform/covid-19-open-data/blob/main/docs/table-vaccinations.md" target="_blank"> Google COVID-19 Open Data </a>.
          </Row>
          <Row>
          Download formatted time-series data for all locations (Right-click-> Save As):
          <a href="https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/G_vacc_num.csv" download target="_blank"> (1) People vaccinated with at least one dose
          </a>, 
          <a href="https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/results/forecasts/G_vacc_full.csv" download target = "_blank"> (2) People vaccinated with full dose </a>.
          </Row>
          <Row>
          Note: We only show the locations for which data is available in the above sources. We assume that previously infected are immune.
          </Row> 
            <Row>
            {<h1>Vaccination Scenario Analysis</h1>}
            </Row>
            <Row>
            <p>
            The following presents the trajectory of COVID-19 in the US states based on the various scenarios. Note that the choices of the scenarios do not reflect the true vaccine availability or efficacy. These scenarios are not actual forecasts, but extrapolations given the assumptions described below and infection and death rates learned from the past. 
			If you are looking for for the "current-trend" forecasts, please see  </p>
			<ul>
			<li><a href='https://scc-usc.github.io/ReCOVER-COVID-19/#/' target='_blank'> this page for the US states and countries around the world </a></li>
			<li><a href='https://scc-usc.github.io/ReCOVER-COVID-19/#row' target='_blank'> this page for Admin 1 (state-level) and Admin 2 (county-level) forecasts of 20,000 locations around the world </a></li>
			</ul>
			
            </Row>
                    <Row>
                    	<Iframe url={url_page}
                    	width="100%"
        				height={(0.9*this.state.height).toString()}
        				/>
                </Row>
            </div></div>
        );
    }
}

export default Scenarios;