import {connectSocket} from '../utils/channel';
import groupBy from 'lodash/groupBy';

export const SELECT_TIMESLOT = 'SELECT_TIMESLOT';
export const CONFIRM_TIMESLOT = 'CONFIRM_TIMESLOT';
export const SELECT_DATE = 'SELECT_DATE';
export const RECEIVE_TIMESLOTS = 'RECEIVE_TIMESLOTS';

const STORE_ID = "1";
let channel;

export function selectDate(date) {
  return dispatch => {
    channel.push("select_day", {date: date})
      .receive("ok", () => dispatch({type: SELECT_DATE, date}))
      .receive("error", () => dispatch({type: "ERROR"}));
  }
}

export function selectTimeslot(timeslot) {
  return (dispatch, getState) => {
    channel.push("select_timeslot", {time: timeslot.time})
      .receive("ok", () => dispatch({type: SELECT_TIMESLOT, timeslot: timeslot}));
  }
}

export function confirmTimeslot() {
  return dispatch => {
    channel.push("confirm_timeslot")
      .receive("ok", () => dispatch({type: CONFIRM_TIMESLOT}));
  }
}

function receiveTimeslots({slots, currentTimeslot}) {
  return {
    type: RECEIVE_TIMESLOTS,
    timeslots: groupBy(slots, 'date'),
    currentTimeslot: currentTimeslot
  }
}

export function connectToChannel() {
  return (dispatch, getState) => {
    const socket = connectSocket({});
    const {orderId} = getState();

    channel = socket.channel(`store_availability:${STORE_ID}`, {orderId: orderId});
    channel.join()
      .receive('ok', () => { console.log('Joined'); })
      .receive('error', (err) => console.error(err));

    channel.on('initial', (payload) => dispatch(receiveTimeslots(payload)));
    channel.on('update', (payload) => dispatch(receiveTimeslots(payload)));
  }
}
