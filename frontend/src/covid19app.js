import React, { Component } from "react";
import Covid19Predict from "./covid19predict";
import { 
  Layout, 
  Menu,
  Row,
  Col, 
  Breadcrumb 
} from 'antd';
import "./covid19app.css";

const { Header, Content, Footer } = Layout;

const navigate = ({key}) => {
  if (key == 'COVID-19 Forecast') {
    document.getElementById("main-content").innerHTML = "<Covid19Predict />";
  } else if (key == 'About Us') {
    document.getElementById("main-content").innerHTML = "<p>hello!</p>;
  }
}

class Covid19App extends Component {
  render() {
    return (
      <div className="app-wrapper">
        <Layout className="app-layout">
          <Header>
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
                 defaultSelectedKeys={['COVID-19 Forecast']} 
                 onClick={navigate}>
                  <Menu.Item key="COVID-19 Forecast">COVID-19 Forecast</Menu.Item>
                  <Menu.Item key="How to Use">How to Use</Menu.Item>
                  <Menu.Item key="About Us">About Us</Menu.Item>
                </Menu>
              </Col>
            </Row>
            
          </Header>

          <Content className="main-content" id="main-content">
            <Covid19Predict />
          </Content>
        </Layout>
        
      </div>
    );
  }
}

export default Covid19App;
