import React, { Component } from "react";
import { List, Avatar } from 'antd';
import "../covid19app.css";
import "./leaderboard.css";
import { number } from "@amcharts/amcharts4/core";
import { icon } from "leaflet";

const fakeData = [
    {
        model: {
            name: "SI-kJalpha - No under-reported positive cases (death prediction)",
            description: "The SI-kJalpha model with no assumptions about under-reporting positive cases."
        },
        evaluation_start: "2020-06-10",
        evaluation_end: "2020-06-17",
        score: 93.2
    },
    {
        model: {
            name: "JHU - IDD (US state level death prediction only)",
            description: "County-level metapopulation model with commuting and stochastic SEIR disease dynamics. \
            The predictions are provided by the Johns Hopkins ID Dynamics COVID-19 Working Group. \
            More info on https://github.com/HopkinsIDD/COVIDScenarioPipeline."
        },
        evaluation_start: "2020-06-07",
        evaluation_end: "2020-06-14",
        score: 89.7
    },
    {
        model: {
            name: "Columbia University - Select (US state level death prediction only)",
            description: "This metapopulation county-level SEIR model makes projections of future COVID-19 deaths. \
            The predictions are provided by the Shaman Lab at Columbia University. \
            More info on https://github.com/shaman-lab/COVID-19Projection."
        },
        evaluation_start: "2020-06-11",
        evaluation_end: "2020-06-17",
        score: 83.2
    },
    {
        model: {
            name: "UCLA - SuEIR (US state level death prediction only)",
            description: "The SuEIR model is a variant of the SEIR model considering both untested and unreported cases. \
            The model takes reopening into consideration and assumes that the contact rate will increase after the reopen.\
            The predictions are provided by the UCLA Statistical Machine Learning Lab. \
            More info on https://github.com/reichlab/covid19-forecast-hub/tree/master/data-processed/UCLA-SuEIR."
        },
        evaluation_start: "2020-06-07",
        evaluation_end: "2020-06-14",
        score: 82.2
    },
    {
        model: {
            name: "SI-kJalpha - 10x under-reported positive cases (death prediction)",
            description: "The SI-kJalpha model with the assumption that observed positive cases are under-reported by 10x."
        },
        evaluation_start: "2020-06-10",
        evaluation_end: "2020-06-17",
        score: 77.3
    }

];

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
                <h1 className="title">US State-level Death Prediction Leaderboard</h1>
                <List
                    className = "leaderboard"
                    itemLayout="horizontal"
                    dataSource={fakeData}
                    renderItem={item => (
                        <List.Item>
                            <List.Item.Meta
                                avatar={this.getAvatar(fakeData.indexOf(item) + 1)}
                                title={<h4 className="model-name" >{item.model.name}</h4>}
                                description={<p className="model-description" >{item.model.description}</p>}
                            />
                            <div className="content">
                                <span className="score">{item.score}</span>
                                <p className="score-description">Evaluation<br /> starts on {item.evaluation_start} <br/>
                                ends on {item.evaluation_end}</p>
                            </div>
                        </List.Item>
                    )}
                />
                <p className="disclaimer">
                    <b>Disclaimer:</b> The above Covid-19 forecast reports may have copyright restrictions. 
                    Although they are open-source under the website link in their descriptions, 
                    they do not account for the specialized features of many business resources.<br /> 
                    All credits goes to the owners of forecast reports.
                    The ReCover-Covid-19 website does not hold responsibility or liability for prediction accuracy
                    of prediction reports that are not generated by USC Data Science lab. 
                    
                </p>
            </div>
        );
    }
}

export default Leaderboard;