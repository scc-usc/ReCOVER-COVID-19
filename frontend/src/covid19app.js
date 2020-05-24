import React, { Component } from "react";
import Covid19Predict from "./covid19predict";
import AboutUS from "./aboutus"
import { 
  Layout,
  Row,
  Col,
  Tabs
} from 'antd';
import "./covid19app.css";

const { Header, Content, Footer } = Layout;

const { TabPane } = Tabs;

class Covid19App extends Component {

  render() {
    return (

      <div className="app-wrapper">
        <Layout className="app-layout">
          <Tabs className="nav-bar" defaultActiveKey="1" type="card">
            <TabPane tab= {
              <img 
                className="logo"
                src="https://identity.usc.edu/files/2011/12/combo_gold_white_cardinal.png"
                alt="USC"
              />
            }></TabPane>
            <TabPane tab="Covid-19 Forecast" key="1">
              <Covid19Predict />
            </TabPane>
            <TabPane tab="About us" key="2">
              <AboutUS />
            </TabPane>
          </Tabs>
        </Layout>
      </div>
    );
  }
}

export default Covid19App;
