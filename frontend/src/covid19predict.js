import React, { PureComponent } from "react";
import Covid19Graph from "./covid19graph";
import ModelAPI from "./modelapi";
import { areaToStr, strToArea } from "./covid19util";
import { test_data } from "./test_data";

import {
  Form,
  Select,
  InputNumber,
  Button,
  Radio,
  Checkbox,
  Slider
} from "antd";

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

    this.state = {
      areas: this.props.areas || [],
      areasList: [],
      distancingOn: true,
      distancingOff: false,
      mainGraphData: {},
      days: 10,
      statistic: "cumulative",
      yScale: "linear"
    };

    this.addAreaByStr = this.addAreaByStr.bind(this);
    this.removeAreaByStr = this.removeAreaByStr.bind(this);
    this.onValuesChange = this.onValuesChange.bind(this);
  }

  componentDidUpdate(prevProps) {
    // Only perform a component update if the user selected a new area on the
    // map, and it hasn't already been selected on the dropdown.
    if (
      this.props.mapSelectedArea !== prevProps.mapSelectedArea &&
      !this.areaIsSelected(this.props.mapSelectedArea)
    ) {
      this.addAreaByStr(areaToStr(this.props.mapSelectedArea));
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

  onValuesChange(changedValues, allValues) {
    if ("days" in changedValues || "socialDistancing" in changedValues) {
      // If either 'days' or the social distancing parameters were changed, we
      // clear our data and do a full reload.
      const prevAreas = this.state.areas;

      // Clear all data and update parameters. The reason we clear 'areas' also
      // is because addAreaByStr will add the values back to 'areas'.
      this.setState(
        {
          days: allValues.days,
          areas: [],
          distancingOn: allValues.socialDistancing.includes("distancingOn"),
          distancingOff: allValues.socialDistancing.includes("distancingOff"),
          mainGraphData: {}
        },
        () => {
          // Add all the areas back.
          prevAreas.forEach(this.addAreaByStr);
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

  render() {
    const { areas, areasList, mainGraphData, statistic, yScale } = this.state;

    // Only show options for countries that have not been selected yet.
    const countryOptions = areasList
      .filter(area => !this.areaIsSelected(area))
      .map(areaToStr)
      .sort()
      .map(s => {
        return <Option key={s}> {s} </Option>;
      });

    return (
      <div className="covid-19-predict">
        <div className="form">
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
              label="Days to Predict"
              name="days"
              rules={[
                { required: true, message: "Please select number of days!" }
              ]}
            >
              <Slider min={0} defaultValue={15} max={99} />
            </Form.Item>
            <Form.Item label="Social Distancing" name="socialDistancing">
              <Checkbox.Group>
                <Checkbox defaultChecked value="distancingOn">
                  On
                </Checkbox>
                <Checkbox value="distancingOff">Off</Checkbox>
              </Checkbox.Group>
            </Form.Item>
          </Form>
          <p>Statistic:</p>
          <Radio.Group value={statistic} onChange={this.handleStatisticSelect}>
            <Radio value="cumulative">Cumulative Cases</Radio>
            <Radio value="delta">New Cases</Radio>
          </Radio.Group>
          <p>
            <br />
            Scale:
          </p>
          <Radio.Group value={yScale} onChange={this.handleYScaleSelect}>
            <Radio value="linear">linear</Radio>
            <Radio value="log">logarithmic</Radio>
          </Radio.Group>
        </div>
        <div className="graph-wrapper">
          <Covid19Graph
            data={mainGraphData}
            statistic={statistic}
            yScale={yScale}
          ></Covid19Graph>
        </div>
      </div>
    );
  }
}

export default Covid19Predict;
