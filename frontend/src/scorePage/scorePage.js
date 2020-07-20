import React, { PureComponent } from "react";
import ModelAPI from "../modelapi";
import { areaToStr, strToArea} from "../covid19util";
import ScoreGraph from "./scoreGraph";
import NewScoreGraph from "./newScoreGraph";
import ScoreMap from './scoreMap';
import "./scorePage.css";

import {
    Form,
    Select,
    Slider,
    Switch,
    Alert,
    Row,
    Col,
    Radio
  } from "antd";

const { Option } = Select;

class ScorePage extends PureComponent{
    constructor(props){
        super(props);
        this.state = {
            areas: this.props.areas || [],
            areasList: [],
            latestDate: "",
            mainGraphData: {},
            weeks: this.props.weeks || 0, // will later be set to be the weeks to the latest date as initial value
            latestWeek: 0, //will change later and remain unchange until database updated
            dynamicMapOn: false,
            noDataError: false,
            errorDescription: "",
            scoreType: "reproduction"
        }  
        
        this.addAreaByStr = this.addAreaByStr.bind(this);
        this.removeAreaByStr = this.removeAreaByStr.bind(this);
        this.onValuesChange = this.onValuesChange.bind(this);
        this.onMapClick = this.onMapClick.bind(this);
        this.onWeeksChange = this.onWeeksChange.bind(this);
        this.switchDynamicMap = this.switchDynamicMap.bind(this);
        this.onAlertClose = this.onAlertClose.bind(this);
        this.onNoData = this.onNoData.bind(this);
        this.generateMarks = this.generateMarks.bind(this);
        this.handleScoreTypeSelect = this.handleScoreTypeSelect.bind(this);
    }

    componentDidMount = ()=>{
        this.formRef = React.createRef();
    
        this.modelAPI = new ModelAPI();

        this.modelAPI.latest_score_date(latestDate => 
            this.setState({
                latestDate: latestDate[0].date,
                weeks: latestDate[0].weeks,
                latestWeek: latestDate[0].weeks
            }, ()=>{
                this.addAreaByStr('US');
                this.formRef.current.setFieldsValue({
                    weeks: this.state.latestWeek,
                });
                this.map.fetchData(this.state.dynamicMapOn);
            })
        );
    
        this.modelAPI.areas(allAreas =>
          this.setState({
            areasList: allAreas
          })
        );
    }

    onMapClick(area) {
        if (!this.areaIsSelected(area)) {
            this.addAreaByStr(areaToStr(area));
        }
    }

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
            this.modelAPI.scores(
            {
                state: areaObj.state,
                country: areaObj.country,
                weeks: this.state.latestWeek,
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
        // If we're here it means the user either added or deleted an area, so we
        // can do a union / intersection to figure out what to add/remove.
        const prevAreas = this.state.areas;
        const newAreas = allValues.areas;
        if (newAreas && prevAreas)
        {
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

    onWeeksChange(weeks) {
        this.setState({ weeks });
        if (this.state.dynamicMapOn) {
            this.map.fetchData(this.state.dynamicMapOn);
        }
    }

    bindRef = ref => { 
        this.map = ref 
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
        const {weeks, lastDate, latestWeek} = this.state;
        let latestDate = new Date(`${lastDate}T00:00`);
        let firstDate = new Date(2020,2,10);
        let currentDate = new Date(2020,2,10);
        currentDate.setDate(currentDate.getDate(Date) + 7*weeks);
        //get the date of the selected date on slider
        let marks = {};
        let i = 0;
        while ( i <= 5 && weeks + i<=latestWeek)
        {
           marks[weeks+i] = `${currentDate.getMonth()+1}/${currentDate.getDate()}`;
           currentDate.setDate(currentDate.getDate(Date) + 7);
           i++;
        }
        i = 1
        currentDate = new Date(2020,2,10);
        currentDate.setDate(currentDate.getDate(Date) + 7*(weeks-1));
        while (i <= 5 && weeks - i >= 0)
        {
            marks[weeks - i] = `${currentDate.getMonth()+1}/${currentDate.getDate()}`;
            currentDate.setDate(currentDate.getDate(Date) - 7);
            i++;
        }
        currentDate = new Date(2020,2,10);
        currentDate.setDate(currentDate.getDate(Date) + 7*weeks);
        return [currentDate, marks];
      }

    
    handleScoreTypeSelect = e =>{
        this.setState({
            scoreType: e.target.value
        });
    }

    render(){
        const {
            areas,
            areasList,
            weeks,
            mainGraphData,
            dynamicMapOn,
            latestWeek,
            noDataError,
            errorDescription,
            scoreType
          } = this.state;
        const countryOptions = areasList
        .filter(area => !this.areaIsSelected(area))
        .map(areaToStr)
        .sort()
        .map(s => {
        return <Option key={s}> {s} </Option>;
        });

        const [currentDate, marks] = this.generateMarks();
        const month = (currentDate.getMonth() + 1)<10?(`0${currentDate.getMonth() + 1}`):(currentDate.getMonth() + 1);
        const date = (currentDate.getDate()<10)?(`0${currentDate.getDate()}`):currentDate.getDate();
        const formatted_current_date = `${month}/${date}`;
        return(
            <div className="score-page">
                <Row type="flex" justify="space-around">
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
                                label="Week to check"
                                name="weeks"
                                rules={[
                                { required: true, message: "Please select the week you want to see" }
                                ]}
                            >
                                <Slider
                                    marks={marks}
                                    initialValue={weeks}
                                    min ={weeks-5>=0?weeks-5: 0}
                                    max={weeks+5<=latestWeek?weeks+5:latestWeek}
                                    onAfterChange={this.onWeeksChange}
                                />
                            </Form.Item>
                        </Form>
                        <div className="radio-group">Data Type:&nbsp;&nbsp;  
                            <Radio.Group
                                value={scoreType}
                                onChange={this.handleScoreTypeSelect}
                            >
                                <Radio value="reproduction">Dynamic Reproduction</Radio>
                                <Radio value="mfr">MFR</Radio>
                            </Radio.Group>
                        </div>
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
                    <ScoreMap className="score-map"
                    triggerRef={this.bindRef}
                    dynamicMapOn={dynamicMapOn}
                    weeks={weeks}
                    latestWeek={latestWeek}
                    onMapClick={this.onMapClick} 
                    onNoData = {this.onNoData}
                    scoreType = {scoreType}
                    />
                </div>
                </Col>
                </Row>
                {areas.length?
                <Row>
                <Col span={24}>
                    <div className="graph-wrapper">
                    <NewScoreGraph
                        data={mainGraphData}
                        date={formatted_current_date}
                        scoreType={scoreType}
                    ></NewScoreGraph>
                    </div>
                </Col>
                </Row>
                : null}
            </div>
        );
    }
}

export default ScorePage;