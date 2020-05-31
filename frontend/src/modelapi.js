import axios from "axios";

// TODO: Update with actual backend URL once backend is up and running.
const API_BASE_URL = process.env.REACT_APP_BACKEND_BASE_URL;

class ModelAPI {
  affected_by(callback) {}

  areas(callback) {
    const endpoint = `${API_BASE_URL}/areas`;
    axios.get(endpoint).then(res => {
      const allAreas = res.data;
      console.log(allAreas);
      callback(allAreas);
    });
  }

  models(callback) {
    const endpoint = `${API_BASE_URL}/models`;
    axios.get(endpoint).then(res => {
      const allModels = res.data;
      console.log(allModels);
      callback(allModels);
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
   * Params should have 'country', 'state', 'days', 'distancing.'
   */
  predict(params, callback) {
    const endpoint = `${API_BASE_URL}/predict`;
    console.log(params);
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
