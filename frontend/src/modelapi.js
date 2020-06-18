import axios from "axios";

// TODO: Update with actual backend URL once backend is up and running.
const API_BASE_URL = process.env.REACT_APP_BACKEND_BASE_URL;

class ModelAPI {
  affected_by(callback) {}

  areas(callback) {
    const endpoint = `${API_BASE_URL}/areas`;
    axios.get(endpoint).then(res => {
      const allAreas = res.data;
      callback(allAreas);
    });
  }

  models(callback) {
    const endpoint = `${API_BASE_URL}/models`;
    axios.get(endpoint).then(res => {
      const allModels = res.data;
      callback(allModels);
    });
  }

  infection_models(callback) {
    const endpoint = `${API_BASE_URL}/infection_models`;
    axios.get(endpoint).then(res => {
      const infectionModels = res.data;
      callback(infectionModels);
    });
  }

  death_models(callback) {
    const endpoint = `${API_BASE_URL}/death_models`;
    axios.get(endpoint).then(res => {
      const deathModels = res.data;
      callback(deathModels);
    });
  }

  cumulative_infections(callback) {
    const endpoint = `${API_BASE_URL}/cumulative_infections`;
    axios.get(endpoint).then(res => callback(res.data));
  }

  /**
   * Params should have 'days', 'model'
   */
  predict_all(params, callback) {
    const endpoint = `${API_BASE_URL}/predict_all`;
    axios.get(endpoint, {
      params: params
    }).then(res => callback(res.data));
  }

  /**
   * Params should have 'country', 'state', 'days', 'distancingOn,' 'distancingOff'
   */
  predict(params, callback) {
    const endpoint = `${API_BASE_URL}/predict`;
    axios
      .get(endpoint, {
        params: params
      })
      .then(res => {
        callback(res.data);
      });
  }

  // get the current date of observed data
  getCurrentDate(callback) {
    const endpoint =  `${API_BASE_URL}/current_date`;
    axios.get(endpoint).then(res => {
      const currentDate = res.data;
      callback(currentDate);
    });
  }

  //check previous data 
  checkHistory(params,callback)
  {
    const endpoint = `${API_BASE_URL}/check_history`;
    axios
      .get(endpoint, {
        params: params
      })
      .then(res => {
        callback(res.data);
      });
  }

  //cumulative for history
  history_cumulative(params, callback) {
    const endpoint = `${API_BASE_URL}/history_cumulative`;
    axios
      .get(endpoint, {
        params: params
      })
      .then(res => {
        callback(res.data);
      });
  }

  //get all quarantine score at a week, parameter: weeks
  scores_all(params, callback) {
    const endpoint = `${API_BASE_URL}/scores_all`;
    axios
      .get(endpoint, {
        params: params
      })
      .then(res => {
        callback(res.data);
      });
  }

  //get all, parameter: state, country, weeks
  scores(params, callback) {
    const endpoint = `${API_BASE_URL}/scores`;
    axios
      .get(endpoint, {
        params: params
      })
      .then(res => {
        callback(res.data);
      });
  }

  //get the latest date which 
  latest_score_date(callback) {
    const endpoint =  `${API_BASE_URL}/latest_score_date`;
    axios.get(endpoint).then(res => {
      const latestDate = res.data;
      callback(latestDate);
    });
  }

  //get the death at latest time
  cumulative_death(params, callback) {
    const endpoint = `${API_BASE_URL}/cumulative_death`;
    axios
      .get(endpoint, {
        params: params
      })
      .then(res => {
        callback(res.data);
      });
  }
}

export default ModelAPI;
