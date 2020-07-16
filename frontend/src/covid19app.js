import React, { Component } from "react";
import Covid19Predict from "./covid19predict";
import AboutUS from "./aboutus";
import ScorePage from './scorePage/scorePage';
import {HashRouter, Route, Redirect, Switch} from 'react-router-dom'; 
import Navbar from "./navbar/navbar";
import 'semantic-ui-css/semantic.min.css';
import "./covid19app.css";
import Leaderboard from "./leaderboard/leaderboard";
import AllPage from "./all_page_pdf/all_page_pdf";

import pdf from "./attention.pdf";

class Covid19App extends Component {
  constructor(props){
    super(props);
    this.state = {
      redirectForecast: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false
    }
  }

  redirectForecast = ()=>{
    this.setState({
      redirectForecast:true,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false
    });
  }

  redirectAbout = ()=>{
    this.setState({
      redirectForecast: false,
      redirectAbout:true,
      redirectScore: false,
      redirectLeaderboard: false
    });
  }

  redirectScore = ()=>{
    this.setState({
      redirectForecast: false,
      redirectAbout:false,
      redirectScore: true,
      redirectLeaderboard: false
    });
  }

  redirectLeaderboard = ()=>{
    this.setState({
      redirectForecast: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: true
    });
  }

  render() {
    const {redirectForecast, redirectAbout, redirectScore, redirectLeaderboard} = this.state;
    let url = window.location.href;
    return (
      <HashRouter basename="/">
        {redirectForecast?<Redirect to="/"/>:null}
        {redirectScore?<Redirect to="/score"/>:null}
        {redirectAbout?<Redirect to="/about"/>:null}
        {redirectLeaderboard?<Redirect to="/leaderboard"/>:null}
        <Navbar redirectForecast = {this.redirectForecast}
                redirectScore = {this.redirectScore}
                redirectAbout = {this.redirectAbout}
                redirectLeaderboard = {this.redirectLeaderboard}
        />
        <Switch>
          <Route exact path='/' 
            render={(props) => <Covid19Predict {...props} />}/>
          <Route exact path='/score' 
            render={(props) => <ScorePage {...props}/>}
          />
          <Route exact path='/about'
            render={(props) => <AboutUS {...props} />} />
          <Route exact path='/leaderboard' 
            render={(props) => <Leaderboard {...props} />}/>
          <Route exact path='/pdf'>
             <AllPage pdf={pdf}/>
          </Route>
        </Switch>
      </HashRouter>
    );
  }
}

export default Covid19App;
