import React, { Component } from "react";
import {
    Menu,
    Row,
    Col,
} from 'antd';

class NavBar extends Component {

    render() {
        return (
            <Row>
                <Col >
                    <img
                        className="logo"
                        src="https://identity.usc.edu/files/2011/12/combo_gold_white_cardinal.png"
                        alt="USC"
                    />
                </Col>
                <Col>
                    <Menu theme="dark"
                        mode="horizontal"
                        defaultSelectedKeys={['COVID-19 Forecast']}>
                        <Menu.Item key="COVID-19 Forecast">COVID-19 Forecast</Menu.Item>
                        <Menu.Item key="How to Use">How to Use</Menu.Item>
                        <Menu.Item key="About Us">About Us</Menu.Item>
                    </Menu>
                </Col>
            </Row>
        );
    }
}

export default NavBar;