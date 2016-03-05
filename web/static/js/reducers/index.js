import {SELECT_TIMESLOT, SELECT_DATE, RECEIVE_TIMESLOTS} from '../actions';
import merge from 'lodash/merge';
import isArray from 'lodash/isArray';

function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  }
  return s4() + s4();
}

const defaultTimeslot = {
  date: null,
  time: null
};

const initialState = {
  timeslots: {},
  orderId: guid(),
  selectedDay: null,
  selectedTimeslot: defaultTimeslot
};

export default function(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_TIMESLOTS:
      const newState = {
        timeslots: action.timeslots,
        selectedTimeslot: action.currentTimeslot || defaultTimeslot
      };
      return merge({}, state, newState, (a, b) => {
        if (isArray(a)) { return b; }
      });
    case SELECT_DATE:
      return merge({}, state, {selectedDay: action.date});
    case SELECT_TIMESLOT:
      return merge({}, state, {selectedTimeslot: action.timeslot});
    default:
      return state;
  }
};
