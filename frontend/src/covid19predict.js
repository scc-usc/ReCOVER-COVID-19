import React, { PureComponent, useState, Sonnet } from "react";
import Covid19Graph from "./covid19graph";
import Covid19Map from "./covid19map";
import ModelAPI from "./modelapi";
import { areaToStr, strToArea, modelToStr } from "./covid19util";
//import { test_data } from "./test_data";
import "./covid19predict.css";
//// import Tabs from 'react-bootstrap/Tabs';
import { Tab, Tabs } from "react-tabify";
//// import Tab from 'react-bootstrap/Tab';
//// import Tabs from "./tabs/Tabs";

import {
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

import { InfoCircleOutlined } from "@ant-design/icons";
import { value } from "numeral";
import RadioGroup from "antd/lib/radio/group";


///////////////// Load area names and population (should switch to backend in the future) //////////////////

import globalLL from "./frontendData/global_lats_longs.txt"
import population from './frontendData/global_population_data.txt'

import Papa from "papaparse";

import ReactGA from "react-ga";
//const Covid19Graph = React.lazy(() =>import("./covid19graph"));
//const Covid19Map = React.lazy(() =>import("./covid19map"));

var global_lat_long;
var populationVect;
var areanames;

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

//////////////////////////////////////////////////////////////////////////////////

const { Option } = Select;

class Covid19Predict extends PureComponent {
  handleYScaleSelect = e => {
    console.log(e);
    this.setState({
      yScale: e.target.value,
    });
  };

  handleStatisticSelect = e => {
    this.setState(
      {
        statistic: e.target.value,
      },
      () => {
        this.map.fetchData(this.state.dynamicMapOn);
      }
    );
  };

  handleDataTypeSelect = e => {
    console.log(e);

    this.setState({
      dataType: e,
    });
  };

  handleMapShownSelect = e => {
    this.setState(
      {
        mapShown: e.target.value,
      },
      () => {
        this.map.fetchData(this.state.dynamicMapOn);
      }
    );
  };

  constructor(props) {
    super(props);
    this.state = {
      areas: this.props.areas || [],
      areasList: [],
      plainareas: [],
      all_populations: [],
      models: this.props.models || ["SI-kJalpha - Default"],
      modelsList: [],
      currentDate: "",
      firstDate: "",
      current: true,
      worst_effort: false,
      best_effort: false,
      mainGraphData: {},
      mainGraphDataShown: {},
      days: 49,
      dynamicMapOn: true,
      perMillion: false,
      dataType: ["confirmed"],
      statistic: "cumulative",
      mapShown: "confirmed",
      yScale: "linear",
      noDataError: false,
      errorDescription: "",
      showControlInstructions: false,
      showMapInstructions: false,
      totalConfirmed: 0,
      totalDeaths: 0,
      width: 0,
      height: 0,
    };

    this.addAreaByStr = this.addAreaByStr.bind(this);
    this.loadAreaNames = this.loadAreaNames.bind(this);
    this.removeAreaByStr = this.removeAreaByStr.bind(this);
    this.onValuesChange = this.onValuesChange.bind(this);
    this.onMapClick = this.onMapClick.bind(this);
    this.onDaysToPredictChange = this.onDaysToPredictChange.bind(this);
    this.switchDynamicMap = this.switchDynamicMap.bind(this);
    this.switchPerMillion = this.switchPerMillion.bind(this);
    this.onAlertClose = this.onAlertClose.bind(this);
    this.onNoData = this.onNoData.bind(this);
    this.generateMarks = this.generateMarks.bind(this);
    this.handleDataTypeSelect = this.handleDataTypeSelect.bind(this);
    this.handleStatisticSelect = this.handleStatisticSelect.bind(this);
    this.handleYScaleSelect = this.handleYScaleSelect.bind(this);
    this.toggleControlInstructions = this.toggleControlInstructions.bind(this);
    this.toggleMapInstructions = this.toggleMapInstructions.bind(this);
    this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
  }

  ////////////////////////////////////
  componentDidMount() {
    ReactGA.initialize('UA-186385643-1');
    ReactGA.pageview('/ReCOVER/main');
    this.updateWindowDimensions();
    window.addEventListener("resize", this.updateWindowDimensions);
    if (this.state.plainareas.length < 1){
            this.loadAreaNames();
          }
  }


  updateWindowDimensions() {
    this.setState({ width: window.innerWidth, height: window.innerHeight });
  }

  ////////////////////////////////////
  componentWillMount = () => {
    this.addAreaByStr("US");
    if (this.state.plainareas.length < 1){
            this.loadAreaNames();
          }

    window.removeEventListener("resize", this.updateWindowDimensions);

    this.formRef = React.createRef();
    this.modelAPI = new ModelAPI();

    this.modelAPI.areas(allAreas =>
      this.setState({
        areasList: allAreas,
      })
    );

    this.modelAPI.infection_models(infectionModels =>
      this.setState(
        {
          modelsList: infectionModels,
        },
        () => {
          this.modelAPI.death_models(deathModels => {
            for (let i = 7; i < deathModels.length; ++i) {
              this.setState(prevState => ({
                modelsList: [...prevState.modelsList, deathModels[i]],
              }));
            }
          });
        }
      )
    );

    this.modelAPI.getCurrentDate(currentDate =>
      this.setState({
        currentDate: currentDate[0].date,
        firstDate: currentDate[0].firstDate,
      })
    );

    this.modelAPI.real_time(global => {
      this.setState({
        totalConfirmed: global.totalConfirmed,
        totalDeaths: global.totalDeaths,
      });
    });
  };


    loadAreaNames(){
    var i;
    var theseareas = [];
    parseData(globalLL, parse_lat_long_global);
    parseData(population, parse_population);
    if(typeof global_lat_long !== 'undefined'){
      for(i=0; i< global_lat_long.length; i++)
      {
        theseareas[i] = global_lat_long[i][0];
      }
      this.setState({plainareas: theseareas}, ()=>{this.reloadAll();});
      this.setState({all_populations: populationVect});
    }
  }

  onMapClick(area) {
    if (!this.areaIsSelected(area)) {
      // this.addAreaByStr(areaToStr(area));
      this.addAreaByStr(area);
    }
  }

  /**
   * Returns true if the area is already selected by the user.
   */
  areaIsSelected(area) {
    if (this.state.areas && area) {
      // const newAreaStr = areaToStr(area);
      // return this.state.areas.includes(newAreaStr);
      return this.state.areas.includes(area);
    }
    return false;
  }

  addAreaByStr(areaStr) {
    const areaObj = strToArea(areaStr);
    var idx = this.state.plainareas.indexOf(areaObj.state);
    if (idx == -1){
      idx = this.state.plainareas.indexOf(areaObj.country);
    }
    //console.log(this.state.plainareas.length);
    //console.log(idx);
    var normalizer = 1;
    if ((idx > -1) && (this.state.perMillion)){
      normalizer = (this.state.all_populations[idx])/1000000;
  }
    this.setState(
      prevState => ({
        areas: [...prevState.areas, areaStr],
      }),
      () => {
        // check if days is positive or negative to decide whether check history or predict future
        if (this.state.days >= 0) {
          this.modelAPI.predict(
            {
              state: areaObj.state,
              country: areaObj.country,
              models: this.state.models,
              days: 98,
              current: this.state.current,
              worst_effort: this.state.worst_effort,
              best_effort: this.state.best_effort,
            },
            data => {
              var data1 = data;
              data1['normalizer'] = normalizer;
              this.setState(prevState => ({
                mainGraphData: {
                  ...prevState.mainGraphData,
                  [areaStr]: data1,
                },
              }));
              this.onDaysToPredictChange(this.state.days);
            }
          );
        } else {
          this.modelAPI.checkHistory(
            {
              state: areaObj.state,
              country: areaObj.country,
              days: this.state.days,
            },
            data => {
              var data1 = data;
              data1['normalizer'] = normalizer;
              this.setState(prevState => ({
                mainGraphData: {
                  ...prevState.mainGraphData,
                  [areaStr]: data1,
                },
              }));
            }
          );
        }
        if (this.formRef.current != null) {
          this.formRef.current.setFieldsValue({
            areas: this.state.areas,
          });
        }
      }
    );
    //console.log(this.state.mainGraphData);
  }

  removeAreaByStr(targetAreaStr) {
    this.setState(prevState => {
      return {
        // Filter out the area / graph data corresponding to the target area
        // string.
        areas: prevState.areas.filter(areaStr => areaStr !== targetAreaStr),
        mainGraphData: Object.keys(prevState.mainGraphData)
          .filter(areaStr => areaStr !== targetAreaStr)
          .reduce((newMainGraphData, areaStr) => {
            return {
              ...newMainGraphData,
              [areaStr]: prevState.mainGraphData[areaStr],
            };
          }, {}),
        mainGraphDataShown: Object.keys(prevState.mainGraphDataShown)
          .filter(areaStr => areaStr !== targetAreaStr)
          .reduce((newMainGraphDataShown, areaStr) => {
            return {
              ...newMainGraphDataShown,
              [areaStr]: prevState.mainGraphDataShown[areaStr],
            };
          }, {})
      };
    });
  }

  /**
   * Returns true if the model is already selected by the user.
   */
  modelIsSelected(model) {
    if (this.state.models && model) {
      const newModelStr = modelToStr(model);
      return this.state.models.includes(newModelStr);
    }
    return false;
  }

  /**
   * onValuesChange is called whenever the values in the form change. Note that
   * days to predict is handled separately by onDaysToPredictChange.
   */
  onValuesChange(changedValues, allValues) {
    const { dataType } = this.state;
    if ("socialDistancing" in changedValues) {
      // If either the social distancing or model parameters were changed, we
      // clear our data and do a full reload. We purposely ignore days to
      // predict here (see onDaysToPredictChange).
      this.setState(
        {
          current: allValues.socialDistancing.includes("current"),
          worst_effort: allValues.socialDistancing.includes("worst_effort"),
          best_effort: allValues.socialDistancing.includes("best_effort"),
        },
        () => {
          this.reloadAll();
        }
      );
    }
    if ("models" in changedValues) {
      this.setState(
        {
          models: changedValues.models,
        },
        () => {
          this.reloadAll();
        }
      );
    } else {
      // If we're here it means the user either added or deleted an area, so we
      // can do a union / intersection to figure out what to add/remove.
      const prevAreas = this.state.areas;
      const newAreas = allValues.areas;

      const areasToAdd = newAreas.filter(
        areaStr => !prevAreas.includes(areaStr)
      );
      const areasToRemove = prevAreas.filter(
        areaStr => !newAreas.includes(areaStr)
      );

      areasToAdd.forEach(this.addAreaByStr);
      areasToRemove.forEach(this.removeAreaByStr);
    }
  }

  /**
   * onDaysToPredictChange is bound to the 'onAfterChange' prop for the
   * slider component, so this function will only be called on the mouseup
   * event (to reduce database load).
   */
  onDaysToPredictChange(days) {
    const prevAreas = this.state.areas;
    let mainGraphDataShown = JSON.parse(JSON.stringify(this.state.mainGraphData));
    if (days >= 0) {
      for (const [areaStr, areaSeries] of Object.entries(mainGraphDataShown)) {
        for (var i = 0; i < mainGraphDataShown[areaStr]['predictions'].length; i++) {
          const timeSeries = areaSeries['predictions'][i]['time_series'];
          mainGraphDataShown[areaStr]['predictions'][i]['time_series'] = timeSeries.slice(0, days == 98? timeSeries.length : -(98 - days) / 7);
        }
      }
    } else {
      for (const [areaStr, areaSeries] of Object.entries(mainGraphDataShown)) {
        mainGraphDataShown[areaStr]['predictions'][0]['time_series'] = [];
        mainGraphDataShown[areaStr]['predictions'][1]['time_series'] = [];
        mainGraphDataShown[areaStr]['observed'] = areaSeries['observed'].slice(0, days/7);
        mainGraphDataShown[areaStr]['observed_deaths'] = areaSeries['observed_deaths'].slice(0, days/7);
      }
    }
    this.setState({
      days: days,
      mainGraphDataShown: mainGraphDataShown
    }, ()=>{
      if (this.state.dynamicMapOn && this.state.models.length !== 0) {
        this.map.fetchData(this.state.dynamicMapOn, days);
      }
    });

  }

  // Set the reference to the map component as a child-component.
  bindRef = ref => {
    this.map = ref;
  };

  /**
   * reloadAll refreshes the prediction data for all currently-selected
   * countries.
   */
  reloadAll() {
    const prevAreas = this.state.areas;
    this.setState(
      {
        areas: [],
        mainGraphData: {},
        mainGraphDataShown: {}
      },
      () => {
          if (this.state.plainareas.length < 1){
            this.loadAreaNames();
            }

        // Add all the areas back.
        prevAreas.forEach(this.addAreaByStr);

        // TODO: Add code for stuff after reload here!
        // Force reload the heatmap, only refetch data when dynamic map is on
        if (this.state.dynamicMapOn && this.state.models.length !== 0) {
          this.map.fetchData(this.state.dynamicMapOn);
        }
      }
    );
  }

  switchDynamicMap(checked) {
    this.setState({
      dynamicMapOn: checked,
    });
    //console.log(this.state.dynamicMapOn);
    this.map.fetchData(checked);
  }

  switchPerMillion(checked) {
    this.setState({
      perMillion: checked,
    }, ()=>{this.reloadAll();});
    this.map.fetchData(this.state.dynamicMapOn);
  }


  //when closing the alert
  onAlertClose = () => {
    this.setState({
      noDataError: false,
    });
  };

  //when encounter an no data error
  onNoData = name => {
    this.setState({
      noDataError: true,
      errorDescription: `There is currently no data for ${name}`,
    });
  };

  generateMarks = () => {
    const { currentDate, days, firstDate } = this.state;
    let date = new Date(`${currentDate}T00:00`);
    let beginDate = new Date(`${firstDate}T00:00`);
    //get the date of the selected date on slider
    date.setDate(date.getDate(Date) + days);
    let marks = {};
    marks[days] = `${date.getMonth() + 1}/${date.getDate()}`;
    // marks for future
    let i = days + 7;
    let skip = 1;
    const skip_factor = 1 + Math.floor(2000.0 / this.state.width);
    while (i < days + 50 && i <= 99) {
      date.setDate(date.getDate() + 7);
      if (!(skip % skip_factor)) {
        marks[i] = `${date.getMonth() + 1}/${date.getDate()}`;
      } else {
        marks[i] = ``;
      }
      i += 7;
      skip += 1;
    }
    // marks for history
    date = new Date(`${currentDate}T00:00`);
    date.setDate(date.getDate(Date) + days);
    date.setDate(date.getDate() - 7);
    i = days - 7;
    skip = 1;
    while (date >= beginDate && i > days - 30) {
      if (!(skip % skip_factor)) {
        marks[i] = `${date.getMonth() + 1}/${date.getDate()}`;
      } else {
        marks[i] = ``;
      }
      date.setDate(date.getDate() - 7);
      i -= 7;
      skip += 1;
    }
    return marks;
  };

  getDaysToFirstDate = () => {
    const { currentDate, firstDate } = this.state;
    let date = new Date(`${currentDate}T00:00`);
    let beginningDate = new Date(`${firstDate}T00:00`);
    return Math.ceil(Math.abs(date - beginningDate) / (1000 * 60 * 60 * 24));
  };

  toggleControlInstructions = () => {
    const showControlInstructions = this.state.showControlInstructions;
    this.setState({
      showControlInstructions: !showControlInstructions,
    });
  };

  toggleMapInstructions = () => {
    const showMapInstructions = this.state.showMapInstructions;
    this.setState({
      showMapInstructions: !showMapInstructions,
    });
  };

  render() {
    const {
      areas,
      areasList,
      models,
      modelsList,
      days,
      mainGraphData,
      mainGraphDataShown,
      dynamicMapOn,
      perMillion,
      dataType,
      statistic,
      mapShown,
      yScale,
      noDataError,
      errorDescription,
    } = this.state;
    const marks = this.generateMarks();
    const daysToFirstDate = this.getDaysToFirstDate();
    // Only show options for countries that have not been selected yet.
    const countryOptions = areasList
      .filter(area => !this.areaIsSelected(area))
      .map(areaToStr)
      .sort()
      .map(s => {
        return <Option key={s}> {s} </Option>;
      });

    const modelOptions = modelsList
      .filter(model => !this.modelIsSelected(model))
      .map(model => {
        return (
          <Option key={model.name} value={model.name}>
            <Tooltip title={model.description} placement="right">
              {model.name}
            </Tooltip>
          </Option>
        );
      });

    const instructionContentStyle = {
      width: "60vh",
    };

    // Instruction messages for each form items.
    const CONTROL_INSTRUCTIONS = {
      area: (
        <p className="instruction">
          Select the areas by clicking on the map or searching in this input
          box.
        </p>
      ),

      model: (
        <div className="instruction">
          <p className="instruction">
            "SI-kJalpha - 20x " assumes that the true positive cases are 20
            times the current reported cases. "SI-kJalpha-Default" is our best
            guess.
          </p>
        </div>
      ),

      date: (
        <p className="instruction">
          Predictions up to the date selected will be shown.
        </p>
      ),

      socialDistancing: (
        <p className="instruction">
          Compare different social distancing scenarios.
        </p>
      ),

      data_type: (
        <p className="instruction">
          Select the forecasts for cumulative infections or/and deaths.
        </p>
      ),

      statistics: (
        <p className="instruction">
          Switch between cumulative view and incident view.
        </p>
      ),

      scale: (
        <p className="instruction">
          Switch between linear view and logarithmic view.
        </p>
      ),
    };

    const MAP_INSTRUCTION = {
      perMillionView: (
        <p className="instruction vertical">
          Turn on to see all the plot and the bubbles based on per million population of the region.
        </p>
      ),
      selectMap: (
        <p className="instruction vertical">
          Hover over the bubbles to see case and death data. Select to add to the plot. Button on the top right to toggle between US states and the country.
        </p>
      ),
      dynamicMap: (
        <p className="instruction vertical">
          Enable the map to dynamically change to reflect the data and
          predictions based on the selected options. Turn off if the interface
          seems slow.
        </p>
      ),

      radioGroup: (
        <p className="instruction vertical">
          Switch between cumulative infection view or death view on the heatmap.
        </p>
      ),
    };

    const tabTheme = {
      tabs: {
        color: "black",
        active: {
          color: "#990000",
        },
      },
    };


    // Generate the global overview paragraph
    let overview = "";

    // In case we cannot fetch data from the external API,
    // the overview will not show up.
    if (this.state.totalConfirmed != 0 && this.state.totalDeaths != 0) {
      const today = new Date();
      const dd = String(today.getDate()).padStart(2, "0");
      const mm = String(today.getMonth() + 1).padStart(2, "0"); //January is 0!
      const yyyy = today.getFullYear();

      //today = mm + '/' + dd + '/' + yyyy;
      const totalConfirmed = this.state.totalConfirmed
        .toString()
        .replace(/\B(?=(\d{3})+(?!\d))/g, ",");
      const totalDeaths = this.state.totalDeaths
        .toString()
        .replace(/\B(?=(\d{3})+(?!\d))/g, ",");
      overview =
        "By " +
        mm +
        "/" +
        dd +
        "/" +
        yyyy +
        ", " +
        totalConfirmed +
        " people around the world have been tested positive, and " +
        totalDeaths +
        " people have died of COVID-19.";
    }

    let confirmed_model_map = "";
    let death_model_map = "";
    for (let i = models.length - 1; i >= 0; i--) {
      if (models[i].substring(0, 10) === "SI-kJalpha") {
        confirmed_model_map = models[i];
        if (death_model_map.length === 0) {
          death_model_map = models[i] + " (death prediction)";
        }
        break;
      } else {
        death_model_map = models[i];
      }
    }

    const Heading = (
      <div id="header" className="text-center">
        <div id="overview">
          <b>{overview}</b>
        </div>
      </div>
    );
    return (
      <div className="covid-19-predict">
        {Heading}
        <div>
          <Row type="flex" justify="center" id="charts">
            {noDataError ? (
              <Alert
                message={`${errorDescription}`}
                description="Please wait for our updates."
                type="error"
                closable
                onClose={this.onAlertClose}
              />
            ) : null}
            <div className="form-column">
              <div>
                <div className="form-wrapper gray" id="graph_options">
                  <Form
                    ref={this.formRef}
                    onValuesChange={this.onValuesChange}
                    initialValues={{
                      areas: areas,
                      models: models,
                      days: 14,
                      socialDistancing: ["current"],
                    }}
                  >
                    <Popover
                      content={CONTROL_INSTRUCTIONS.area}
                      placement="top"
                      visible={this.state.showControlInstructions}
                    >
                      <Form.Item
                        style={{ marginBottom: "0px" }}
                        label="Areas"
                        name="areas"
                        rules={[
                          { required: true, message: "Please select areas!" },
                        ]}
                      >
                        <Select
                          mode="multiple"
                          style={{ width: "100%" }}
                          placeholder="Select Areas"
                        >
                          {countryOptions}
                        </Select>
                      </Form.Item>
                    </Popover>
                    <Popover
                      content={CONTROL_INSTRUCTIONS.model}
                      placement="rightTop"
                      visible={this.state.showControlInstructions}
                      //content={<div style={instructionContentStyle} />}
                      align={{
                        overflow: { adjustX: false, adjustY: false },
                      }}
                    >
                      <Form.Item
                        style={{ marginBottom: "0px" }}
                        label="Models:"
                        name="models"
                        rules={[
                          {
                            required: true,
                            message: "Please select a prediction model!",
                          },
                        ]}
                      >
                        <Select
                          mode="single"
                          style={{ width: "100%" }}
                          placeholder="Select Prediction Models"
                        >
                          {modelOptions}
                        </Select>
                      </Form.Item>
                    </Popover>
                    <Popover
                      placement="rightBottom"
                      content={CONTROL_INSTRUCTIONS.date}
                      visible={this.state.showControlInstructions}
                    >
                      <Form.Item label="Date to Predict" name="days">
                        <Slider
                          marks={marks}
                          min={
                            days - 30 >= -daysToFirstDate
                              ? days - 30
                              : -daysToFirstDate
                          }
                          initialValue={days}
                          max={days + 50 <= 99 ? days + 50 : 99}
                          onAfterChange={this.onDaysToPredictChange}
                          step={null}
                          tooltipVisible={false}
                        />
                      </Form.Item>
                    </Popover>
                    {/* <Popover
                      content={CONTROL_INSTRUCTIONS.socialDistancing}
                      placement="right"
                      visible={this.state.showControlInstructions}
                    >
                      <Form.Item
                        label="Social Distancing"
                        name="socialDistancing"
                        style={{ marginBottom: "0px" }}
                      >
                        <Checkbox.Group style={{ width: "100%" }}>
                          <Row>
                            <Checkbox defaultChecked value="current">
                              Current Trend
                            </Checkbox>
                            <Checkbox value="worst_effort">
                              Worst Distancing Effort
                            </Checkbox>
                            <Checkbox value="best_effort">
                              Best Distancing Effort
                            </Checkbox>
                          </Row>
                        </Checkbox.Group>
                      </Form.Item>
                    </Popover> */}
                  </Form>
                  <Form>
                    <Popover
                      content={CONTROL_INSTRUCTIONS.data_type}
                      placement="right"
                      visible={this.state.showControlInstructions}
                    >
                      <Form.Item
                        label="Data Types"
                        style={{ marginBottom: "0px" }}
                      >
                        <Checkbox.Group
                          value={dataType}
                          onChange={this.handleDataTypeSelect}
                        >
                          <Checkbox defaultChecked value="confirmed">
                            Confirmed Cases
                          </Checkbox>
                          <Checkbox value="death">Deaths</Checkbox>
                        </Checkbox.Group>
                      </Form.Item>
                    </Popover>
                    <Popover
                      content={CONTROL_INSTRUCTIONS.statistics}
                      placement="right"
                      visible={this.state.showControlInstructions}
                    >
                      <Form.Item
                        label="Statistic"
                        style={{ marginBottom: "0px" }}
                      >
                        <Radio.Group
                          value={statistic}
                          onChange={this.handleStatisticSelect}
                        >
                          <Radio value="cumulative">Cumulative Cases</Radio>
                          <Radio value="delta">New Cases</Radio>
                        </Radio.Group>
                      </Form.Item>
                    </Popover>
                    <Popover
                      content={CONTROL_INSTRUCTIONS.scale}
                      placement="right"
                      visible={this.state.showControlInstructions}
                    >
                      <Form.Item label="Scale" style={{ marginBottom: "0px" }}>
                        <Radio.Group
                          value={yScale}
                          onChange={this.handleYScaleSelect}
                        >
                          <Radio value="linear">Linear</Radio>
                          <Radio value="log">Logarithmic</Radio>
                        </Radio.Group>
                      </Form.Item>
                    </Popover>
                  </Form>
                </div>
              </div>
              {areas.length ? (
                <div>
                  <div className="graph-wrapper">
                    <Covid19Graph
                      data={mainGraphDataShown}
                      perMillion = {perMillion}
                      dataType={dataType}
                      onNoData={this.onNoData}
                      statistic={statistic}
                      yScale={yScale}
                    ></Covid19Graph>
                  </div>
                </div>
              ) : null}
            </div>
            <div className="map-column">
              <div className="form-wrapper gray" id="graph_options">
                <div>
                  <span className="map-control">
                  <table><tbody><tr><td>
                    <Popover
                      content={MAP_INSTRUCTION.dynamicMap}
                      placement="bottom"
                      visible={this.state.showMapInstructions}
                    >
                      <Switch defaultChecked onChange={this.switchDynamicMap} />
                      <b>&nbsp;&nbsp;Dynamic Map&nbsp;&nbsp;</b>
                    </Popover></td>
                    <td><Popover
                      content={MAP_INSTRUCTION.perMillionView}
                      placement="top"
                      visible={this.state.showMapInstructions}
                    >&nbsp;&nbsp;&nbsp;
                      <Switch onChange={this.switchPerMillion} />
                      <b>&nbsp;&nbsp;Data/Million Population &nbsp;&nbsp;</b>
                    </Popover></td></tr></tbody></table>

                  </span>
                </div>
              </div>
              <div>
                <div className="map-wrapper">
                <Popover
                      content={MAP_INSTRUCTION.selectMap}
                      placement="leftBottom"
                      visible={this.state.showMapInstructions}
                    >
                  <Covid19Map
                    className="map"
                    triggerRef={this.bindRef}
                    dynamicMapOn={dynamicMapOn}
                    perMillion = {perMillion}
                    days={days}
                    confirmed_model={confirmed_model_map}
                    death_model={death_model_map}
                    onMapClick={this.onMapClick}
                    onNoData={this.onNoData}
                    statistic={statistic}
                    dataType={mapShown}
                  />
                  </Popover>
                </div>
              </div>
              <div>
                <div className="instruction-buttons-wrapper">
                  <Button
                    className="instruction-button"
                    onClick={this.toggleControlInstructions}
                  >
                    {this.state.showControlInstructions == false
                      ? "Help with controls"
                      : "Close control instructions"}
                  </Button>
                  <Button
                    className="instruction-button"
                    onClick={this.toggleMapInstructions}
                  >
                    {this.state.showMapInstructions == false
                      ? "Help with the map"
                      : "Close map instructions"}
                  </Button>
                </div>
              </div>
            </div>
          </Row>
        </div>
      </div>
    );
  }
}

export default Covid19Predict;
