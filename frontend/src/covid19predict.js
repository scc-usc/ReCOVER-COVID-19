import React, { PureComponent } from "react";
import Covid19Graph from "./covid19graph";
import Covid19Map from "./covid19map";
import ModelAPI from "./modelapi";
import { areaToStr, strToArea, modelToStr } from "./covid19util";
import { test_data } from "./test_data";

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
} from "antd";

import {
  InfoCircleOutlined
} from '@ant-design/icons';

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
    });
  };

  constructor(props) {
    super(props);

    this.formRef = React.createRef();

    this.modelAPI = new ModelAPI();

    this.modelAPI.areas(allAreas =>
      this.setState({
        areasList: allAreas
      })
    );

    this.modelAPI.models(allModels =>
      this.setState({
        modelsList: allModels
      })
    );

    this.state = {
      areas: this.props.areas || [],
      areasList: [],
      models: this.props.models || [],
      modelsList: [],
      distancingOn: true,
      distancingOff: false,
      mainGraphData: {},
      days: 10,
      dynamicMapOn: false,
      statistic: "cumulative",
      yScale: "linear"
    };

    this.addAreaByStr = this.addAreaByStr.bind(this);
    this.removeAreaByStr = this.removeAreaByStr.bind(this);
    this.onValuesChange = this.onValuesChange.bind(this);
    this.onMapClick = this.onMapClick.bind(this);
    this.onDaysToPredictChange = this.onDaysToPredictChange.bind(this);
    this.switchDynamicMap = this.switchDynamicMap.bind(this);
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
          .filter(areaStr => areaStr != targetAreaStr)
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
    if ("socialDistancing" in changedValues || "models" in changedValues) {
      // If either the social distancing or model parameters were changed, we
      // clear our data and do a full reload. We purposely ignore days to
      // predict here (see onDaysToPredictChange).

      this.setState(
        {
          models: allValues.models,
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
        // Force reload the heatmap
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


  render() {
    const {
      areas,
      areasList,
      modelsList,
      days,
      mainGraphData,
      dynamicMapOn,
      statistic,
      yScale
    } = this.state;

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
          <Option key={model.name}>
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
        <div className="left-col">
          <div className="form-wrapper">
            <Form
              ref={this.formRef}
              onValuesChange={this.onValuesChange}
              initialValues={{
                areas: areas,
                days: 10,
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
                label="Under-reporting Cases:"
                name="models"
                rules={[
                  { required: true, message: "Please select reporting ratio!" }
                ]}
              >
                <Select
                  mode="multiple"
                  style={{ width: "100%" }}
                  placeholder="Select Reporting Ratio"
                >
                  {modelOptions}
                </Select>
              </Form.Item>
              <Form.Item
                label="Days to Predict"
                name="days"
                rules={[
                  { required: true, message: "Please select number of days!" }
                ]}
              >
                <Slider
                  min={0}
                  initialValue={15}
                  max={99}
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
                    On
                  </Checkbox>
                  <Checkbox value="distancingOff"> 
                    Off
                  </Checkbox>
                </Checkbox.Group>
              </Form.Item>
              </Popover>
            </Form>
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
          <div className="map-wrapper">
            <Covid19Map
              triggerRef={this.bindRef}
              dynamicMapOn={this.state.dynamicMapOn}
              days={days}
              model={this.state.models == null || this.state.models.length ===0? "" : this.state.models[this.state.models.length-1]}
              onMapClick={this.onMapClick} 
            />
          </div>
        </div>
        <div className="right-col">
          <div className="graph-wrapper">
            <Covid19Graph
              data={mainGraphData}
              statistic={statistic}
              yScale={yScale}
            ></Covid19Graph>
          </div>
        </div>
      </div>
    );
  }
}

export default Covid19Predict;
