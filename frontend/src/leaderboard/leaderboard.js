import React, { Component } from "react";
import { List, Avatar, Row, Col } from 'antd';
import "../covid19app.css";
import "./leaderboard.css";
import nyt_graph from "../img/nyt_graph.png"
import jhu_graph from "../img/jhu_graph.png"
import usf_graph from "../img/usf_graph.png"

const data = {
    jhu: {
        runningAvgRankings: [
            {
                model: {
                    name: "SI-kJalpha using the JHU dataset",
                    description: "This is our SI-kJalpha trained on the Johns Hopkins University's Covid19 dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 79.45
            },
            {
                model: {
                    name: "Covid19 Simulator",
                    description: "An interactive tool developed by researchers at Mass General Hospital, \
                    Harvard Medical School, Georgia Tech and Boston Medical Center to inform COVID-19 intervention policy decisions in the US.",
                    link: "https://covid19sim.org/"
                },
                RMSE: 83.68
            },
            {
                model: {
                    name: "YYG - ParamSearch",
                    description: "Based on the SEIR model to make daily projections regarding \
                    COVID-19 infections and deaths in 50 US states. The model accounts for \
                    state reopenings and its effects on infections and deaths. \
                    The model's contributor is Youyang Gu.",
                    link: "http://covid19-projections.com/about/"
                },
                RMSE: 90.76
            },
        ],
        recentRankings: [
            {
                model: {
                    name: "SI-kJalpha using the Johns Hopkins University's Covid19 dataset",
                    description: "This is our SI-kJalpha trained on the Johns Hopkins University's Covid19 dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 79.45
            },
            {
                model: {
                    name: "Covid19 Simulator",
                    description: "An interactive tool developed by researchers at Mass General Hospital, \
                    Harvard Medical School, Georgia Tech and Boston Medical Center to inform COVID-19 intervention policy decisions in the US.",
                    link: "https://covid19sim.org/"
                },
                RMSE: 83.68
            },
            {
                model: {
                    name: "YYG - ParamSearch",
                    description: "Based on the SEIR model to make daily projections regarding \
                    COVID-19 infections and deaths in 50 US states. The model accounts for \
                    state reopenings and its effects on infections and deaths. \
                    The model's contributor is Youyang Gu.",
                    link: "http://covid19-projections.com/about/"
                },
                RMSE: 90.76
            },
        ]
    },
    nyt: {
        runningAvgRankings: [
            {
                model: {
                    name: "SI-kJalpha using NYTimes dataset",
                    description: "This is our SI-kJalpha trained on the New York Times dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 75.05
            },
            {
                model: {
                    name: "CovidActNow - SEIR_CAN",
                    description: "SEIR model by CovidActNow research team. \
                    The model forecasts cumulative deaths, incident deaths, incident hospitalizations \
                    by fitting predicted cases, deaths, and hospitalizations to the observations.",
                    link: "https://covidactnow.org/"
                },
                RMSE: 92.82
            },
            {
                model: {
                    name: "UCLA - SuEIR",
                    description: "SEIR model by UCLA Statistical Machine Learning Lab. \
                    The model takes reopening into consideration and assumes contact rate will increase after the reopen.",
                    link: "https://covid19.uclaml.org/"
                },
                RMSE: 95.48
            }
        ],
        recentRankings: [
            {
                model: {
                    name: "SI-kJalpha using NYTimes dataset",
                    description: "This is our SI-kJalpha trained on the New York Times dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 75.05
            },
            {
                model: {
                    name: "CovidActNow - SEIR_CAN",
                    description: "SEIR model by CovidActNow research team. \
                    The model forecasts cumulative deaths, incident deaths, incident hospitalizations \
                    by fitting predicted cases, deaths, and hospitalizations to the observations.",
                    link: "https://covidactnow.org/"
                },
                RMSE: 92.82
            },
            {
                model: {
                    name: "UCLA - SuEIR",
                    description: "SEIR model by UCLA Statistical Machine Learning Lab. \
                    The model takes reopening into consideration and assumes contact rate will increase after the reopen.",
                    link: "https://covid19.uclaml.org/"
                },
                RMSE: 95.478
            }
        ]

    },
    usafacts: {
        runningAvgRankings: [
            {
                model: {
                    name: "SI-kJalpha using the USAFACTS dataset",
                    description: "This is our SI-kJalpha trained on the USAFACTS Covid19 dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 79.11
            },
            {
                model: {
                    name: "Columbia University - SELECT",
                    description: "A metapopulation county-level SEIR model by Columbia University.\
                    The model projects future COVID-19 incidence and deaths.",
                    link: "https://blogs.cuit.columbia.edu/jls106/publications/covid-19-findings-simulations/"
                },
                RMSE: 110.01
            },
            {
                model: {
                    name: "JHU - IDD",
                    description: " County-level metapopulation model by Johns Hopkins ID Dynamics COVID-19 Working Group \
                    with commuting and stochastic SEIR disease dynamics with social-distancing indicators.",
                    link: "https://github.com/HopkinsIDD/COVIDScenarioPipeline"
                },
                RMSE: 145.52
            },
        ],
        recentRankings: [
            {
                model: {
                    name: "SI-kJalpha using the USAFACTS dataset",
                    description: "This is our SI-kJalpha trained on the USAFACTS Covid19 dataset.",
                    link: "https://scc-usc.github.io/ReCOVER-COVID-19/"
                },
                RMSE: 79.11
            },
            {
                model: {
                    name: "Columbia University - SELECT",
                    description: "A metapopulation county-level SEIR model by Columbia University.\
                    The model projects future COVID-19 incidence and deaths.",
                    link: "https://blogs.cuit.columbia.edu/jls106/publications/covid-19-findings-simulations/"
                },
                RMSE: 110.01
            },
            {
                model: {
                    name: "JHU - IDD",
                    description: " County-level metapopulation model by Johns Hopkins ID Dynamics COVID-19 Working Group \
                    with commuting and stochastic SEIR disease dynamics with social-distancing indicators.",
                    link: "https://github.com/HopkinsIDD/COVIDScenarioPipeline"
                },
                RMSE: 145.52
            },
        ]
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
                        <Col span={8}>
                            <h1 className="title">Leaderboard of models on NYTimes dataset</h1>
                            {/* <h2 className="title">Running Average Performance</h2> */}
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
                                            <span>RMSE: <span className="score">{item.RMSE}</span></span>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        </Col>
                        <Col span={8}>
                            <h1 className="title">Leaderboard of models on JHU dataset</h1>
                            {/* <h2 className="title">Running Average Performance</h2> */}
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
                            {/* <h2 className="title">Running Average Performance</h2> */}
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
                            <img className="graph" src={nyt_graph}  />
                        </Col>
                        <Col span={8}>
                            <img className="graph" src={jhu_graph}  />
                        </Col>
                        <Col span={8}>
                        <img className="graph" src={usf_graph}  />
                        </Col>
                    </Row>

                    {/* Code below are recent performance leaderboards. */}
                    {/* <Row>
                        <Col span={8}>
                            <h2 className="title">Recent Performance (from 2020-06-08)</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={fakeData}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(fakeData.indexOf(item) + 1)}
                                            title={<h4 className="model-name" >{item.model.name}</h4>}
                                        // description={<p className="model-description" >{item.model.description}</p>}
                                        />
                                        <div className="content">
                                            <span className="score">{item.score}</span>
                                            <p className="score-description">Evaluation<br /> starts on {item.evaluation_start} <br />
                                    ends on {item.evaluation_end}</p>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        </Col>
                        <Col span={8}>
                            <h2 className="title">Recent Performance (from 2020-06-08)</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={fakeData}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(fakeData.indexOf(item) + 1)}
                                            title={<h4 className="model-name" >{item.model.name}</h4>}
                                        // description={<p className="model-description" >{item.model.description}</p>}
                                        />
                                        <div className="content">
                                            <span className="score">{item.score}</span>
                                            <p className="score-description">Evaluation<br /> starts on {item.evaluation_start} <br />
                                    ends on {item.evaluation_end}</p>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        </Col>
                        <Col span={8}>
                            <h2 className="title">Recent Performance (from 2020-06-08)</h2>
                            <List className="leaderboard"
                                itemLayout="horizontal"
                                dataSource={fakeData}
                                renderItem={item => (
                                    <List.Item>
                                        <List.Item.Meta
                                            avatar={this.getAvatar(fakeData.indexOf(item) + 1)}
                                            title={<h4 className="model-name" >{item.model.name}</h4>}
                                        // description={<p className="model-description" >{item.model.description}</p>}
                                        />
                                        <div className="content">
                                            <span className="score">{item.score}</span>
                                            <p className="score-description">Evaluation<br /> starts on {item.evaluation_start} <br />
                                    ends on {item.evaluation_end}</p>
                                        </div>
                                    </List.Item>
                                )}
                            />
                        </Col>
                    </Row> */}

                    <p className="disclaimer">
                        <b>Disclaimer:</b> The above Covid-19 forecast reports may have copyright restrictions. 
                        You may visit the website of their original work by clicking their model names. <br />
                        Although they are open-source under their website links, 
                        they do not account for the specialized features of many business resources.
                        All credits goes to the owners of forecast reports. <br /> 
                        The ReCover-Covid-19 website does not hold responsibility or liability for prediction accuracy
                        of prediction reports that are not generated by USC Data Science lab.
                    </p> 
                </div>
            </div>
        );
    }
}

export default Leaderboard;