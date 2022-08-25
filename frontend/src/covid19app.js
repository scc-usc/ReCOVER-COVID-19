import React, { Component, Suspense } from "react";
//import Covid19Predict from "./covid19predict";
import AboutUS from "./aboutus";
import Announcements from "./announcement";
//import ScorePage from './scorePage/scorePage';
import {HashRouter, Route, Redirect, Switch} from 'react-router-dom'; 
import Navbar from "./navbar/navbar";
import 'semantic-ui-css/semantic.min.css';
import "./covid19app.css";
//import Leaderboard from "./leaderboard/leaderboard";
//import Highlights from "./highlights/highlights";
//import RoW from "./RoW/RoW";
const Covid19_us = React.lazy(() =>import("./covid19_us"));
const Covid19_global = React.lazy(()=>import("./country_level/covid19_global"));
const RoW = React.lazy(()=>import("./RoW/RoW"));
const Leaderboard = React.lazy(()=>import("./leaderboard/leaderboard"));
const Highlights = React.lazy(()=>import("./highlights/highlights"));
const ScorePage = React.lazy(()=>import("./scorePage/scorePage"));
const Scenarios = React.lazy(()=>import("./scenarios/scenarios"));

class Covid19App extends Component {
  constructor(props){
    super(props);
    this.state = {
      redirectScenarios: false,
      redirectForecast: false,
      redirectGlobal: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false,
      redirectHighlights: false,
      redirectRoW: false
    }
  }

  redirectForecast = ()=>{
    this.setState({
      redirectScenarios: false,
      redirectForecast:true,
      redirectGlobal: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false,
      redirectHighlights: false,
      redirectRoW: false
    });
  }

  redirectGlobal = ()=>{
    this.setState({
      redirectScenarios: false,
      redirectForecast:true,
      redirectGlobal: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false,
      redirectHighlights: false,
      redirectRoW: false
    });
  }

  redirectAbout = ()=>{
    this.setState({
      redirectScenarios: false,
      redirectForecast: false,
      redirectGlobal: false,
      redirectAbout:true,
      redirectScore: false,
      redirectLeaderboard: false,
      redirectHighlights: false,
      redirectRoW: false
    });
  }

  redirectScore = ()=>{
    this.setState({
      redirectScenarios: false,
      redirectForecast: false,
      redirectGlobal: false,
      redirectAbout:false,
      redirectScore: true,
      redirectHighlights: false,
      redirectLeaderboard: false,
      redirectRoW: false
    });
  }

  redirectLeaderboard = ()=>{
    this.setState({
      redirectScenarios: false,
      redirectForecast: false,
      redirectGlobal: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: true,
      redirectHighlights: false,
      redirectRoW: false
    });
  }

  redirectHighlights = ()=>{
    this.setState({
      redirectScenarios: false,
      redirectForecast: false,
      redirectGlobal: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false,
      redirectHighlights: true,
      redirectRoW: false
    });
  }

  redirectRoW = ()=>{
    this.setState({
      redirectScenarios: false,
      redirectForecast: false,
      redirectGlobal: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false,
      redirectHighlights: false,
      redirectRoW: true
    });
  }
    redirectScenarios = ()=>{
    this.setState({
      redirectScenarios: true,
      redirectForecast: false,
      redirectGlobal: false,
      redirectAbout: false,
      redirectScore: false,
      redirectLeaderboard: false,
      redirectHighlights: false,
      redirectRoW: true
    });
  }

  render() {
    const {redirectForecast, redirectGlobal, redirectAbout, redirectScore, redirectLeaderboard, redirectHighlights, redirectRoW, redirectScenarios} = this.state;
    return (
      <Suspense fallback = {<div>Loading...</div>}>
      <HashRouter basename="/">
        {redirectForecast?<Redirect to="/"/>:null}
        {redirectForecast?<Redirect to="/global"/>:null}
        {redirectHighlights?<Redirect to="/highlights"/>:null}
        {redirectScore?<Redirect to="/score"/>:null}
        {redirectAbout?<Redirect to="/about"/>:null}
        {redirectLeaderboard?<Redirect to="/leaderboard"/>:null}
        {redirectLeaderboard?<Redirect to="/row"/>:null}
        <Navbar redirectForecast = {this.redirectForecast}
        		redirectHighlights = {this.redirectHighlights}
                redirectScore = {this.redirectScore}
                redirectAbout = {this.redirectAbout}
                redirectLeaderboard = {this.redirectLeaderboard}
                redirectRoW = {this.redirectRoW}
        />
        <Switch>
          <Route exact path='/' 
            render={(props) => <Covid19_us {...props} />}/>
          {/*<Route exact path='/score' 
            render={(props) => <ScorePage {...props}/>}
          />*/}
          <Route exact path='/about'
            render={(props) => <AboutUS {...props} />} />
            <Route exact path='/global'
            render={(props) => <Covid19_global {...props} />} />
          <Route exact path='/leaderboard' 
            render={(props) => <Leaderboard {...props} />}/>
          <Route exact path='/highlights'
            render={(props) => <Highlights {...props} />}/>
          <Route exact path='/row'
            render={(props) => <RoW {...props} />}/>
            <Route exact path='/scenarios'
            render={(props) => <Scenarios {...props} />}/>
            <Route exact path='/announcement'
            render={(props) => <Announcements {...props} />}/>
        </Switch>
      </HashRouter>
      </Suspense>
    );
  }
}

export default Covid19App;
