import React, { Component } from "react";
import {
    Menu,
    Row,
    Col
} from 'antd';
import "./navbar.css";

class NavBar extends Component {

    constructor(props){
        super(props);
        this.state = {
            activateItem: 'forecast'
        };
    }

    handleItemClick = (e) => 
    {
        const {redirectForecast, redirectAbout, redirectScore} = this.props;
        const {key} = e;
        this.setState({
            activeItem: e.key
        });
        if (key === "forecast")
        {
            redirectForecast();
        }
        else if (key === "information")
        {
            redirectAbout();
        }
        else
        {
            redirectScore();
        }
    }

    render() {
        return (
            <Row className="navbar-container">
            <Col >
                <img
                    className="logo"
                    src="https://identity.usc.edu/files/2011/12/combo_gold_white_cardinal.png"
                    alt="USC"
                />
            </Col>
            <Col>
                <Menu theme="light"
                    mode="horizontal"
                    onClick={this.handleItemClick}
                    defaultSelectedKeys={['forecast']}>
                    <Menu.Item key="forecast">COVID-19 Forecast</Menu.Item>
                    <Menu.Item key="quarantine-score">Quarantine Score</Menu.Item>
                    <Menu.Item key="information">About Us</Menu.Item>
                </Menu>
            </Col>
        </Row>
        );
    }
}

export default NavBar;