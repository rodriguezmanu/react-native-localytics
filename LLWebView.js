// LLWebView.js
import { PropTypes } from 'prop-types';
import React from 'react';
import { View, NativeModules, requireNativeComponent, findNodeHandle, UIManager, Platform } from 'react-native';
const { LLLocalytics } = NativeModules;

class LLWebViewComponent extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return <LLWebView {...this.props} ref={(mv) => this.webViewRef = mv} />;
  }

  componentDidMount() {
  	//grab a reference to the react-native id for this native component
    this.webViewHandle = findNodeHandle(this.webViewRef);
  }

  componentWillUnmount() {
  	if (Platform.OS === 'ios') {
  	  NativeModules.LLWebViewManager.dismiss();
  	} else {
  	  //Dispatch to react-native to inform Android/iOS about message 0 - which will trigger a dismiss impression.
  	  UIManager.dispatchViewManagerCommand(this.webViewHandle, 0, null);
  	}
  }
}

LLWebViewComponent.propTypes = {
  ...View.propTypes,
  campaign: PropTypes.number.isRequired,
};

var propTypes = {
  name: 'LLWebView',
  propTypes: LLWebViewComponent.propTypes,
};

const LLWebView = requireNativeComponent(`LLWebView`, LLWebViewComponent, propTypes);

export default LLWebViewComponent;