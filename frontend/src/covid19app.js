import React, { Component } from "react";
import Covid19Map from "./covid19map";
import Covid19Predict from "./covid19predict";

import "./covid19app.css";

class Covid19App extends Component {
  constructor() {
    super();

    this.state = {
      mapSelectedArea: null
    };
  }

  onMapClick = area => {
    this.setState({
      mapSelectedArea: area
    });
  };

  render() {
    const { mapSelectedArea } = this.state;

    return (
      <div className="app-wrapper">
        <div className="predict-wrapper">
          <Covid19Predict mapSelectedArea={mapSelectedArea} />
        </div>
        <div className="map-wrapper">
          <Covid19Map onMapClick={this.onMapClick} />
        </div>
      </div>
    );
  }
}

export default Covid19App;
