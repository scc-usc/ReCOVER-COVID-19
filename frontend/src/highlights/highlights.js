import React, { Component } from "react";
import { List, Avatar, Row, Col } from 'antd';
import Iframe from 'react-iframe';
import "../covid19app.css";
import "./highlights.css";
import { Button } from "antd";


const url_page = "https://htmlpreview.github.io/?https://raw.githubusercontent.com/scc-usc/ReCOVER-COVID-19/master/frontend/src/highlights/highlights.html";

class Highlights extends Component {


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
                    	<Iframe url={url_page}
                    	width="100%"
        				height={(0.9*this.state.height).toString()}
        				/>
                </Row>
            </div></div>
        );
    }
}

export default Highlights;