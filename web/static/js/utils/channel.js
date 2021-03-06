import {Socket} from 'phoenix';

export function connectSocket() {
  const socket = new Socket("/socket", {
    logger: ((kind, msg, data) => { console.log(`${kind}: ${msg}`, data) })
  });

  socket.connect();
  return socket;
}

