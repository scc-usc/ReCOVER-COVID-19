import React, { Component } from "react";
import { List, Avatar, Row, Col } from 'antd';
import "../covid19app.css";
import "./leaderboard.css";
import nyt_graph from "./img/nyt_graph.png"
import jhu_graph from "./img/jhu_graph.png"
import usf_graph from "./img/usf_graph.png"
import all_graph from "./img/all_graph.png"

const data = {
    jhu: {
runningAvgRankings: [
	{
	 model: {
 name: "SIkJa_USC",
 description: "This is our SI-kJalpha model.",
 link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
},
 RMSE: 37.2
},	{
	 model: {
 name: "YYG_ParamSearch",
 description: "Based on the SEIR model to make daily projections regarding COVID-19 infections and deaths in 50 US states. The model's contributor is Youyang Gu.",
 link: "http://covid19-projections.com/about/"
},
 RMSE: 38.6
},	{
	 model: {
 name: "Covid19Sim_Simulator",
 description: "An interactive tool developed by researchers at Mass General Hospital, Harvard Medical School, Georgia Tech and Boston Medical Center.",
 link: "https://covid19sim.org/"
},
 RMSE: 59.81
},	{
	 model: {
 name: "UCLA_SuEIR",
 description: "SEIR model by UCLA Statistical Machine Learning Lab.",
 link: "https://covid19.uclaml.org/"
},
 RMSE: 62.95
},	{
	 model: {
 name: "CU_select",
 description: "A metapopulation county-level SEIR model by Columbia University.",
 link: "https://blogs.cuit.columbia.edu/jls106/publications/covid-19-findings-simulations/"
},
 RMSE: 72.5
},	{
	 model: {
 name: "JHU_IDD_CovidSP",
 description: "County-level metapopulation model by Johns Hopkins ID Dynamics COVID-19 Working Group.",
 link: "https://github.com/HopkinsIDD/COVIDScenarioPipeline"
},
 RMSE: 87.49
},	{
	 model: {
 name: "IowaStateLW_STEM",
 description: "A COVID19 forecast project led by Lily Wang in Iowa State University.",
 link: "https://covid19.stat.iastate.edu"
},
 RMSE: 91.94
},	{
	 model: {
 name: "CovidActNow_SEIR_CAN",
 description: "SEIR model by the CovidActNow research team.",
 link: "https://covidactnow.org/"
},
 RMSE: 110.36
},],
recentRankings: [
	{
	 model: {
 name: "SIkJa_USC",
 description: "This is our SI-kJalpha model.",
 link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
},
 RMSE: 23.6
},	{
	 model: {
 name: "YYG_ParamSearch",
 description: "Based on the SEIR model to make daily projections regarding COVID-19 infections and deaths in 50 US states. The model's contributor is Youyang Gu.",
 link: "http://covid19-projections.com/about/"
},
 RMSE: 25.09
},	{
	 model: {
 name: "UCLA_SuEIR",
 description: "SEIR model by UCLA Statistical Machine Learning Lab.",
 link: "https://covid19.uclaml.org/"
},
 RMSE: 28.64
},	{
	 model: {
 name: "CU_select",
 description: "A metapopulation county-level SEIR model by Columbia University.",
 link: "https://blogs.cuit.columbia.edu/jls106/publications/covid-19-findings-simulations/"
},
 RMSE: 52.23
},	{
	 model: {
 name: "JHU_IDD_CovidSP",
 description: "County-level metapopulation model by Johns Hopkins ID Dynamics COVID-19 Working Group.",
 link: "https://github.com/HopkinsIDD/COVIDScenarioPipeline"
},
 RMSE: 56.64
},	{
	 model: {
 name: "Covid19Sim_Simulator",
 description: "An interactive tool developed by researchers at Mass General Hospital, Harvard Medical School, Georgia Tech and Boston Medical Center.",
 link: "https://covid19sim.org/"
},
 RMSE: NaN
},	{
	 model: {
 name: "CovidActNow_SEIR_CAN",
 description: "SEIR model by the CovidActNow research team.",
 link: "https://covidactnow.org/"
},
 RMSE: NaN
},	{
	 model: {
 name: "IowaStateLW_STEM",
 description: "A COVID19 forecast project led by Lily Wang in Iowa State University.",
 link: "https://covid19.stat.iastate.edu"
},
 RMSE: NaN
},]
    }
};

class Leaderboard extends Component {
    getAvatar(number) {
        let icon_src = "";
        switch (number) {
            case 1:
                icon_src = "https://img.icons8.com/officel/80/000000/medal2.png";
                break;
            case 2:
                icon_src = "https://img.icons8.com/officel/80/000000/medal-second-place.png";
                break;
            case 3:
                icon_src = "https://img.icons8.com/officel/80/000000/medal2-third-place.png";
                break;
            default:
                icon_src = "https://img.icons8.com/carbon-copy/100/000000/" + number + "-circle.png";
                break;
        }

        return <Avatar className="rank-number" src={icon_src} alt="" />;

    };

    render() {
        return (
            <div className="page-wrapper">
                <div className="grid">
                    <Row>
                        
                        <Col span={12}>
                            <h2 className="title">Running Average Performance</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={data.jhu.runningAvgRankings}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(data.jhu.runningAvgRankings.indexOf(item) + 1)}
                                            title={<a className="model-name" href={item.model.link}>{item.model.name}</a>}
                                            description={item.model.description}
                                        />
                                        <div className="content">
                                            <span>RMSE: <span className="score">{item.RMSE}</span></span>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        </Col>
                        <Col span={12}>
                            <h2 className="title">Recent Performance (from 2020-08-16)</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={data.jhu.recentRankings}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(data.jhu.recentRankings.indexOf(item) + 1)}
                                            title={<a className="model-name" href={item.model.link}>{item.model.name}</a>}
                                            description={item.model.description}
                                        />
                                        <div className="content">
                                            <span>RMSE: <span className="score">{item.RMSE}</span></span>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        </Col>
                    </Row> 

                    <Row>
                        <div className="main-graph-container">
                            <img className="graph" src={all_graph} />
                        </div>
                        
                    </Row>

		            <p className="clarification">
                        <b>Evaluation method:</b> We have recently moved the evaluation to JHU dataset only as majority of the forecasting teams are now using it. <br />
                        Our forecasts used here are taken from the our <a href='https://github.com/scc-usc/ReCOVER-COVID-19/tree/master/results/forecasts'> github repo </a>.
                        The chosen evaluation metric is Root Mean Squared Error (RMSE) of weekly new deaths computed <br />
                        over the next two weeks from the day of the forecasts. <br />
                        Please contact us at <a className="article-anchor" href="mailto:ajiteshs@usc.edu">ajiteshs@usc.edu</a>  
                        to add your model to the leaderboard.
                    </p>
                    <p className="disclaimer">
                        <b>Disclaimer:</b> The above Covid-19 forecast reports may have copyright restrictions. 
                        You may visit the website of their original work by clicking on their model names. <br />
                        All credits for predictions go to the respective owners of the forecast reports.
                        The ReCover-Covid-19 website does not hold responsibility or liability for prediction accuracy
                        of prediction reports that are not generated by USC Data Science lab.
                    </p> 
                </div>
            </div>
        );
    }
}

export default Leaderboard;