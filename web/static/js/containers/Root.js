import React, { Component, PropTypes } from 'react';
import { connect } from 'react-redux';
import { map } from 'lodash';
import { selectDate, selectTimeslot, connectToChannel, confirmTimeslot } from '../actions';
import keys from 'lodash/keys';
import DayPicker from '../components/DayPicker';
import Timeslot from '../components/Timeslot';

class Root extends Component {
  componentDidMount() {
    const { dispatch } = this.props;
    dispatch(connectToChannel());
  }

  render() {
    const {
      orderId,
      days,
      timeslots,
      selectedDay,
      selectedTimeslot,
      dispatch
    } = this.props;

    if (!days.length) {
      return (
        <div>Loading...</div>
      );
    }

    return (
      <div>
        <p>
          Order: {orderId}<br />
          Selected: {selectedTimeslot.date} - {selectedTimeslot.time}
        </p>

        <div className="days">
          <h3>Days</h3>
          {map(days, (day) => (
            <DayPicker
              key={day}
              day={day}
              selected={day === selectedDay}
              onClick={() => dispatch(selectDate(day))}
            />
          ))}
        </div>

        <div className="timeslots">
          <h3>Times</h3>
          {map(timeslots, (timeslot) => (
            <Timeslot
              key={`${timeslot.date}.${timeslot.time}`}
              time={timeslot.time}
              available={timeslot.available}
              selected={timeslot.date == selectedTimeslot.date &&
                        timeslot.time === selectedTimeslot.time}
              onClick={() => dispatch(selectTimeslot(timeslot))}
            />
          ))}
        </div>

        {selectedTimeslot.time &&
         <button onClick={() => dispatch(confirmTimeslot())}>
           Confirm
         </button>}

      </div>
    );
  }
}

function mapStateToProps({timeslots, selectedTimeslot, selectedDay, orderId}) {
  const days = keys(timeslots);
  const times = timeslots[selectedDay] || [];

  return {
    orderId,
    selectedTimeslot,
    selectedDay,
    days,
    timeslots: times
  }
}

export default connect(mapStateToProps)(Root);
