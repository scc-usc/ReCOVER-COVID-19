import React, { PureComponent } from "react";
import Covid19Graph from "./covid19graph";
import Covid19Map from "./covid19map";
import ModelAPI from "./modelapi";
import { areaToStr, strToArea, modelToStr } from "./covid19util";
import { test_data } from "./test_data";
import "./covid19predict.css";

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
  Col
} from "antd";


import {
  InfoCircleOutlined
} from '@ant-design/icons';
import { value } from "numeral";

const { Option } = Select;

class Covid19Predict extends PureComponent {
  handleYScaleSelect = e => {
    this.setState({
      yScale: e.target.value
    });
  };

  handleStatisticSelect = e => {
    this.setState({
      statistic: e.target.value
    }, () => {
      this.reloadAll();
    });

  };

  handleDataTypeSelect = e => {
    if (e.target.value === "confirmed") {
      this.modelAPI.infection_models(infection_models => {
        this.setState({
          modelsList: infection_models,
          dataType: e.target.value,
          models: ['SI-kJalpha - No under-reported positive cases (default)']
        }, ()=>{
          this.formRef.current.setFieldsValue({
            models: this.state.models
          });
          this.reloadAll();
          if (!this.state.dynamicMapOn)
          {
            this.map.fetchData(this.state.dynamicMapOn);
          }
        });
      });
    } 
    else {
      this.modelAPI.death_models(death_models =>{
          this.setState({
            modelsList: death_models,
            dataType: e.target.value,
            models: ['SI-kJalpha - No under-reported positive cases (death prediction)']
          }, ()=>{
            this.formRef.current.setFieldsValue({
              models: this.state.models
            });
            this.reloadAll();
            if (!this.state.dynamicMapOn)
            {
              this.map.fetchData(this.state.dynamicMapOn);
            }
          }); 
        });
    }
  };

  constructor(props) {
    super(props);
    this.state = {
      areas: this.props.areas || [],
      areasList: [],
      models: this.props.models || ['SI-kJalpha - No under-reported positive cases (default)'],
      modelsList: [],
      currentDate: "",
      distancingOn: true,
      distancingOff: false,
      mainGraphData: {},
      days: 0,
      dynamicMapOn: false,
      dataType: "confirmed",
      statistic: "cumulative",
      yScale: "linear",
      noDataError: false,
      errorDescription: ""
    };

    this.addAreaByStr = this.addAreaByStr.bind(this);
    this.removeAreaByStr = this.removeAreaByStr.bind(this);
    this.onValuesChange = this.onValuesChange.bind(this);
    this.onMapClick = this.onMapClick.bind(this);
    this.onDaysToPredictChange = this.onDaysToPredictChange.bind(this);
    this.switchDynamicMap = this.switchDynamicMap.bind(this);
    this.onAlertClose = this.onAlertClose.bind(this);
    this.onNoData = this.onNoData.bind(this);
    this.generateMarks = this.generateMarks.bind(this);
    this.handleModelChange = this.handleModelChange.bind(this);
    this.handleDataTypeSelect = this.handleDataTypeSelect.bind(this);
    this.handleStatisticSelect = this.handleStatisticSelect.bind(this);
    this.handleYScaleSelect = this.handleYScaleSelect.bind(this);
  }

  componentWillMount = ()=>{
    this.addAreaByStr('US');

    this.formRef = React.createRef();

    this.modelAPI = new ModelAPI();

    this.modelAPI.areas(allAreas =>
      this.setState({
        areasList: allAreas
      })
    );

    this.modelAPI.infection_models(infectionModels =>
      this.setState({
        modelsList: infectionModels
      })
    );

    this.modelAPI.getCurrentDate(currentDate => 
      this.setState({
        currentDate: currentDate[0].date
      })
    );
  }

  onMapClick(area) {
    if (!this.areaIsSelected(area)) {
      this.addAreaByStr(areaToStr(area));
    }
  }

  /**
   * Returns true if the area is already selected by the user.
   */
  areaIsSelected(area) {
    if (this.state.areas && area) {
      const newAreaStr = areaToStr(area);
      return this.state.areas.includes(newAreaStr);
    }
    return false;
  }

  addAreaByStr(areaStr) {
    const areaObj = strToArea(areaStr);

    this.setState(
      prevState => ({
        areas: [...prevState.areas, areaStr]
      }),
      () => {
        // check if days is positive or negative to decide whether check history or predict future
        if (this.state.days >= 0){
          this.modelAPI.predict(
            {
              state: areaObj.state,
              country: areaObj.country,
              models: this.state.models,
              days: this.state.days,
              distancingOn: this.state.distancingOn,
              distancingOff: this.state.distancingOff
            },
            data => {
              this.setState(prevState => ({
                mainGraphData: {
                  ...prevState.mainGraphData,
                  [areaStr]: data
                }
              }));
            }
          );
        }
        else{
          this.modelAPI.checkHistory(
            {
              state: areaObj.state,
              country: areaObj.country,
              days: this.state.days
            }, 
            data =>{
              this.setState(prevState => ({
                mainGraphData: {
                  ...prevState.mainGraphData,
                  [areaStr]: data
                }
              }));
            }

          );
        }

        this.formRef.current.setFieldsValue({
          areas: this.state.areas
        });
      }
    );
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
              [areaStr]: prevState.mainGraphData[areaStr]
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
    if ("socialDistancing" in changedValues) {
      // If either the social distancing or model parameters were changed, we
      // clear our data and do a full reload. We purposely ignore days to
      // predict here (see onDaysToPredictChange).

      this.setState(
        {
          distancingOn: allValues.socialDistancing.includes("distancingOn"),
          distancingOff: allValues.socialDistancing.includes("distancingOff")
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

  handleModelChange(value) {
    this.setState({
        models: value
     }, () => {
      this.reloadAll();
    });
  }

  /**
   * onDaysToPredictChange is bound to the 'onAfterChange' prop for the
   * slider component, so this function will only be called on the mouseup
   * event (to reduce database load).
   */
  onDaysToPredictChange(days) {
    const prevAreas = this.state.areas;
    this.setState({ days }, () => {
      this.reloadAll();
    });
  }

  // Set the reference to the map component as a child-component.
  bindRef = ref => { 
    this.map = ref 
  }

  /**
   * reloadAll refreshes the prediction data for all currently-selected
   * countries.
   */
  reloadAll() {
    const prevAreas = this.state.areas;
    this.setState(
      {
        areas: [],
        mainGraphData: {}
      },
      () => {
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
      dynamicMapOn: checked
    });
    this.map.fetchData(checked);
  }

  //when closing the alert
  onAlertClose = ()=>{
    this.setState({
      noDataError: false
    });
  }

  //when encounter an no data error
  onNoData = (name) =>{
    this.setState({
      noDataError: true,
      errorDescription: `There is currently no data for ${name}`
    })
  }

  generateMarks = ()=>{
    const {currentDate, days} = this.state;
    let date = new Date(`${currentDate}T00:00`);
    let firstDate = new Date(2020,0,22);
    //get the date of the selected date on slider
    date.setDate(date.getDate(Date) + days);
    let marks = {};
    marks[days] = `${date.getMonth()+1}/${date.getDate()}`;
    // marks for future
    let i = days+7
    while (i < days+50 && i<=99)
    {
       date.setDate(date.getDate() + 7);
       marks[i] = `${date.getMonth()+1}/${date.getDate()}`;
       i+=7;
    }
    // marks for history
    date = new Date(`${currentDate}T00:00`);
    date.setDate(date.getDate(Date) + days);
    date.setDate(date.getDate() - 7);
    i = days-7;
    while (date >= firstDate && i > days-30){
      marks[i] = `${date.getMonth()+1}/${date.getDate()}`;
      date.setDate(date.getDate() - 7);
      i -= 7;
    }
    return marks;
  }

  getDaysToFirstDate = ()=>{
    const {currentDate} = this.state;
    let date = new Date(`${currentDate}T00:00`);
    let firstDate = new Date(2020,0,22);
    return Math.ceil(Math.abs(date - firstDate)/ (1000 * 60 * 60 * 24));
  }

  render() {
    const {
      areas,
      areasList,
      models,
      modelsList,
      days,
      mainGraphData,
      dynamicMapOn,
      dataType,
      statistic,
      yScale,
      noDataError,
      errorDescription
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

      // The clarification message to be shown for the "social distancing" option.
      const SOCIAL_DISTANCING_CLARIFICATION = (
        <p>
          The trend until March 18th has been used as a proxy for "Social distancing off". <br />
          For modeling details, please see: 
          <a href="https://arxiv.org/abs/2004.11372"> https://arxiv.org/abs/2004.11372</a>.
        </p>
      );
    return (
      <div className="covid-19-predict">
        <Row type="flex" justify="space-around">
        {/* <div className="left-col"> */}
        <Col span={10}>
        {noDataError?
          <Alert
          message= {`${errorDescription}`}
          description= "Please wait for our updates."
          type="error"
          closable
          onClose={this.onAlertClose}
        />: null
        }
          <div className="form-wrapper">
            <Form
              ref={this.formRef}
              onValuesChange={this.onValuesChange}
              initialValues={{
                areas: areas,
                models: models,
                socialDistancing: ["distancingOn"]
              }}
            >
              <Form.Item
                label="Areas"
                name="areas"
                rules={[{ required: true, message: "Please select areas!" }]}
              >
                <Select
                  mode="multiple"
                  style={{ width: "100%" }}
                  placeholder="Select Areas"
                >
                  {countryOptions}
                </Select>
              </Form.Item>
              <Form.Item
                label="Models:"
                name="models"
                rules={[
                  { required: true, message: "Please select a prediction model!" }
                ]}
              >
                <Select
                  mode="multiple"
                  style={{ width: "100%" }}
                  placeholder="Select Prediction Models"
                  initialvalue = {models}
                  onChange = {this.handleModelChange}
                >
                  {modelOptions}
                </Select>
              </Form.Item>
              <Form.Item
                label="Date to Predict"
                name="days"
                rules={[
                  { required: true, message: "Please select number of days!" }
                ]}
              >
                <Slider
                  marks={marks}
                  min={days-30>=-daysToFirstDate?days-30:-daysToFirstDate}
                  initialValue={days}
                  max={days+50<=99?days+50:99}
                  onAfterChange={this.onDaysToPredictChange}
                />
              </Form.Item>

              <Popover 
                content={SOCIAL_DISTANCING_CLARIFICATION} 
                title="Social Distancing Clarification"
                placement="topLeft"
              >
              <Form.Item label="Social Distancing" name="socialDistancing">
                <Checkbox.Group>
                  <Checkbox defaultChecked value="distancingOn">
                    Current Trend
                  </Checkbox>
                  <Checkbox value="distancingOff"> 
                    Social Distancing Off
                  </Checkbox>
                </Checkbox.Group>
              </Form.Item>
              </Popover>
            </Form>
            <div>Data Type:&nbsp;&nbsp;  
              <Radio.Group
                value={dataType}
                onChange={this.handleDataTypeSelect}
              >
                <Radio value="confirmed">Confirmed Cases</Radio>
                <Radio value="death">Deaths</Radio>
              </Radio.Group>
            </div>
            <br />
            <div>Statistic:&nbsp;&nbsp;  
              <Radio.Group
                value={statistic}
                onChange={this.handleStatisticSelect}
              >
                <Radio value="cumulative">Cumulative Cases</Radio>
                <Radio value="delta">New Cases</Radio>
              </Radio.Group>
            </div>
            <br />
            <div>
              Scale:&nbsp;&nbsp;  
              <Radio.Group value={yScale} onChange={this.handleYScaleSelect}>
                <Radio value="linear">linear</Radio>
                <Radio value="log">logarithmic</Radio>
              </Radio.Group>
            </div>
            <br />
            <p>
              Dynamic Map:&nbsp;&nbsp;  
              <Switch 
                onChange={this.switchDynamicMap} 
              />
            </p>
          </div>
        </Col>
        <Col span={14}>
          <div className="map-wrapper">
            <Covid19Map className="map"
              triggerRef={this.bindRef}
              dynamicMapOn={dynamicMapOn}
              days={days}
              model={this.state.models == null || this.state.models.length ===0? "" : this.state.models[this.state.models.length-1]}
              onMapClick={this.onMapClick} 
              statistic={statistic}
              dataType = {dataType}
            />
          </div>
        {/* </div> */}
        </Col>
        </Row>
        {areas.length?
          <Row>
          <Col span={24}>
          {/* <div className="right-col"> */}
            <div className="graph-wrapper">
              <Covid19Graph
                data={mainGraphData}
                dataType={dataType}
                onNoData = {this.onNoData}
                statistic={statistic}
                yScale={yScale}
              ></Covid19Graph>
            </div>
          {/* </div> */}
          </Col>
          </Row>
        : null}
      </div>
    );
  }
}

export default Covid19Predict;
