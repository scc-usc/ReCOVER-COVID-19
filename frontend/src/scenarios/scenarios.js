import React, { Component } from "react";
import { List, Avatar, Row, Col } from 'antd';
import Iframe from 'react-iframe';
import "../covid19app.css";
import "./scenarios.css";
import { Button } from "antd";
import ReactGA from "react-ga";

const url_page = "https://htmlpreview.github.io/?https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/frontend/src/scenarios/scenario_plots.html";

class Scenarios extends Component {


	constructor() {
		super();
		this.state = {
			width: 0, 
			height: 0,
			};
  			this.updateWindowDimensions = this.updateWindowDimensions.bind(this);
	}

	componentDidMount() {
  		this.updateWindowDimensions();
  		window.addEventListener('resize', this.updateWindowDimensions);
      ReactGA.initialize('UA-186385643-1');
      ReactGA.pageview('/ReCOVER/scenarios');
	}

	componentWillUnmount() {
  		window.removeEventListener('resize', this.updateWindowDimensions);
	}

	updateWindowDimensions() {
  		this.setState({ width: window.innerWidth, height: window.innerHeight });
	}

    render() {
        return (
            <div className="page-wrapper">
            <div className="grid">
            <Row>
            <p>
            The following presents the trajectory of COVID-19 in the US states based on the various scenarios. Note that the choices of the scenarios do not reflect the true vaccine availability or efficacy. These scenarios are not actual forecasts, but extrapolations given the assumptions described below and infection and death rates learned from the past. 
			If you are looking for for the "current-trend" forecasts, please see 
			<ul>
			<li><a href='https://scc-usc.github.io/ReCOVER-COVID-19/#/' target='_blank'> this page for the US states and countries around the world </a></li>
			<li><a href='https://scc-usc.github.io/ReCOVER-COVID-19/#row' target='_blank'> this page for Admin 1 (state-level) and Admin 2 (county-level) forecasts of 20,000 locations around the world </a></li>
			</ul>
			</p>
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