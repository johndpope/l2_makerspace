// Connect and handle rosbridge communications

class ROSBridge {
  setUser(username) {
    this.username = username;
  }

  setHandlers(topicHandlers) {
    this.handlers = {};
    for (let topic of Object.keys(topicHandlers)) {
      this.handlers[`/${this.username}/${topic}`] = topicHandlers[topic];
    }
  }

  setAdvertisedTopics(topics) {
    this.advertised = topics;
  }

  connect(uri) {
    this.socket = new WebSocket("ws://penguin.linux.test:4243");
    this.socket.onopen = this._onOpen.bind(this);
    this.socket.onmessage = this._onMessage.bind(this);
    this.socket.onerror = this._onError.bind(this);
    this.socket.onclose = this._onClose.bind(this);
  }

  _onOpen() {
    console.log("[open] Connection established");
    for (let advert of Object.keys(this.advertised)) {
      const topic = `/${this.username}/${advert}`;
      this.socket.send(JSON.stringify({
        op: 'advertise',
        topic,
        type: this.advertised[advert],
      }));
      console.log(`Advertising ${topic}`);
    }
    for (let topic of Object.keys(this.handlers)) {
      this.socket.send(JSON.stringify({
        op: 'subscribe', 
        topic,
        type: 'std_msgs/Int64',
      }));
      console.log(`Subscribed to ${topic}`);
    }
  }

  _onClose(event) {
    if (event.wasClean) {
      console.log(`[close] Connection closed cleanly, code=${event.code} reason=${event.reason}`);
    } else {
      // e.g. server process killed or network down
      // event.code is usually 1006 in this case
      console.log('[close] Connection died');
    }
  }

  _onError(error) {
    console.log(`[error] ${error.message}`);
  }

  _onMessage(event) {
    console.log(`[message] Data received from server: ${event.data}`);
    try {
      const msg = JSON.parse(event.data);
      if (msg.op === 'publish' && this.handlers[msg.topic]) {
        this.handlers[msg.topic](msg.msg);
      }
    } catch (e) {
      console.log("Failed to parse message:", text);
      return;
    }
  }

  publish(topic, msg) {
    this.socket.send(JSON.stringify({
      op: "publish",
      topic: `/${this.username}/${topic}`,
      msg,
    }));
  }
}

const bridge = new ROSBridge();
export default bridge;
