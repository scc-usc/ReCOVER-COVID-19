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
                    name: "USC - SI-kJalpha using the JHU ",
                    description: "This is our SI-kJalpha trained on the Johns Hopkins University's Covid19 dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 33.55
            },
            {
                model: {
                    name: "YYG - ParamSearch",
                    description: "Based on the SEIR model to make daily projections regarding \
                    COVID-19 infections and deaths in 50 US states. \
                    The model's contributor is Youyang Gu.",
                    link: "http://covid19-projections.com/about/"
                },
                RMSE: 39.77
            },
            {
                model: {
                    name: "Covid19 Simulator",
                    description: "An interactive tool developed by researchers at Mass General Hospital, \
                    Harvard Medical School, Georgia Tech and Boston Medical Center.",
                    link: "https://covid19sim.org/"
                },
                RMSE: 54.14
            },
        ],
        recentRankings: [
            {
                model: {
                    name: "YYG - ParamSearch",
                    description: "Based on the SEIR model to make daily projections regarding \
                    COVID-19 infections and deaths in 50 US states. \
                    The model's contributor is Youyang Gu.",
                    link: "http://covid19-projections.com/about/"
                },
                RMSE: 40.39
            },

            {
                model: {
                    name: "USC - SI-kJalpha using the Johns Hopkins University's Covid19 ",
                    description: "This is our SI-kJalpha trained on the Johns Hopkins University's Covid19 dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 44.95
            },
            
            {
                model: {
                    name: "Covid19 Simulator",
                    description: "An interactive tool developed by researchers at Mass General Hospital, \
                    Harvard Medical School, Georgia Tech and Boston Medical Center.",
                    link: "https://covid19sim.org/"
                },
                RMSE: 61.30
            },
        ]
    },
    nyt: {
        runningAvgRankings: [
            {
                model: {
                    name: "USC - SI-kJalpha using the NYTimes ",
                    description: "This is our SI-kJalpha trained on the New York Times dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 41.90
            },
		{
                model: {
                    name: "UCLA - SuEIR",
                    description: "SEIR model by UCLA Statistical Machine Learning Lab.",
                    link: "https://covid19.uclaml.org/"
                },
                RMSE: 75.61
            },
            {
                model: {
                    name: "Iowa State Lily Wang's Research Group - Spatiotemporal Epidemic Modeling",
                    description: "A COVID19 forecast project led by Lily Wang in Iowa State University.",
                    link: "https://covid19.stat.iastate.edu"
                },
                RMSE: 104.25
            },
            {
                model: {
                    name: "CovidActNow - SEIR_CAN",
                    description: "SEIR model by the CovidActNow research team.",
                    link: "https://covidactnow.org/"
                },
                RMSE: 123.78
            },

            

        ],
        recentRankings: [
            {
                model: {
                    name: "USC - SI-kJalpha using the NYTimes ",
                    description: "This is our SI-kJalpha trained on the New York Times dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 44.54
            },
            {
                model: {
                    name: "UCLA - SuEIR",
                    description: "SEIR model by UCLA Statistical Machine Learning Lab.",
                    link: "https://covid19.uclaml.org/"
                },
                RMSE: 64.58
            },
	{
           model: {
                    name: "Iowa State Lily Wang's Research Group - Spatiotemporal Epidemic Modeling",
                    description: "A COVID19 forecast project led by Lily Wang in Iowa State University.",
                    link: "https://covid19.stat.iastate.edu"
                },
                RMSE: 79.40
            },
            {
                model: {
                    name: "CovidActNow - SEIR_CAN",
                    description: "SEIR model by the CovidActNow research team.",
                    link: "https://covidactnow.org/"
                },
                RMSE: "N/A"
            },
            

        ]

    },
    usafacts: {
        runningAvgRankings: [
            {
                model: {
                    name: "USC - SI-kJalpha using the USAFACTS ",
                    description: "This is our SI-kJalpha trained on the USAFACTS Covid19 dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 42.45
            },
            {
                model: {
                    name: "Columbia University - SELECT",
                    description: "A metapopulation county-level SEIR model by Columbia University.",
                    link: "https://blogs.cuit.columbia.edu/jls106/publications/covid-19-findings-simulations/"
                },
                RMSE: 83.89
            },
            {
                model: {
                    name: "JHU - IDD",
                    description: " County-level metapopulation model by Johns Hopkins ID Dynamics COVID-19 Working Group.",
                    link: "https://github.com/HopkinsIDD/COVIDScenarioPipeline"
                },
                RMSE: 102.28
            },
        ],
        recentRankings: [
            {
                model: {
                    name: "USC - SI-kJalpha using the USAFACTS ",
                    description: "This is our SI-kJalpha trained on the USAFACTS Covid19 dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 44.74
            },
            
            {
                model: {
                    name: "JHU - IDD",
                    description: " County-level metapopulation model by Johns Hopkins ID Dynamics COVID-19 Working Group.",
                    link: "https://github.com/HopkinsIDD/COVIDScenarioPipeline"
                },
                RMSE: 72.25
            },
            {
                model: {
                    name: "Columbia University - SELECT",
                    description: "A metapopulation county-level SEIR model by Columbia University.",
                    link: "https://blogs.cuit.columbia.edu/jls106/publications/covid-19-findings-simulations/"
                },
                RMSE: 76.31
            },

        ]
    },
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
                        <Col span={8}>
                            <h1 className="title">Leaderboard of models on NYTimes dataset</h1>
                            <h2 className="title">Running Average Performance</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={data.nyt.runningAvgRankings}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(data.nyt.runningAvgRankings.indexOf(item) + 1)}
                                            title={<a className="model-name" href={item.model.link}>{item.model.name}</a>}
                                            description={item.model.description}
                                        />
                                        <div className="content">
                                            <span className="score-description">RMSE: <span className="score">{item.RMSE}</span></span>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        </Col>
                        <Col span={8}>
                            <h1 className="title">Leaderboard of models on JHU dataset</h1>
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
                        <Col span={8}>
                        <h1 className="title">Leaderboard of models on USAFACTS dataset</h1>
                            <h2 className="title">Running Average Performance</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={data.usafacts.runningAvgRankings}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(data.usafacts.runningAvgRankings.indexOf(item) + 1)}
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
                        <Col span={8}>
                            <h2 className="title">Recent Performance (from 2020-06-22)</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={data.nyt.recentRankings}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(data.nyt.recentRankings.indexOf(item) + 1)}
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
                        <Col span={8}>
                            <h2 className="title">Recent Performance (from 2020-06-22)</h2>
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
                        <Col span={8}>
                            <h2 className="title">Recent Performance (from 2020-06-22)</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={data.usafacts.recentRankings}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(data.usafacts.recentRankings.indexOf(item) + 1)}
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
                        <Col span={8}>
                            <img className="graph" src={nyt_graph}  />
                        </Col>
                        <Col span={8}>
                            <img className="graph" src={jhu_graph}  />
                        </Col>
                        <Col span={8}>
                        <img className="graph" src={usf_graph}  />
                        </Col>
                    </Row>
                    <Row>
                        <div className="main-graph-container">
                            <img className="graph" src={all_graph} />
                        </div>
                        
                    </Row>

		            <p className="clarification">
                        <b>Evaluation method:</b> Since there are some discrepancies among different data sources (JHU, NY Times, and USA Facts), 
                        we performed a separate evaluation for each dataset. <br />
                        We trained our model using each of the three datasets and use the forecasts 
                        in the respective evaluations. 
                        The chosen evaluation metric is Root Mean Squared Error (RMSE) of daily new deaths computed <br />
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