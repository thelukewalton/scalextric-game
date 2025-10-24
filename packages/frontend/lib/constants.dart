// Defaults for the application

// Server connection
const defaultServerUrl = '192.168.0.101';
const defaultRFIDReaderUrl = '192.168.0.102';
const defaultRestPort = '13000';
const defaultWebsocketPort = '18080';

/// Circuit
const defaultCircuitName = 'Zebra';
const defaultCircuitLength = 12.0; // In metres

// Game play
const defaultPracticeLaps = 3;
const defaultQualifyingLaps = 5;
const defaultRaceLaps = 7;

const defaultEventName = 'Zebra';
const defaultRaceLights = 4;
const defaultScannedThingName = 'badge';
const defaultRaceMode = 'QUALIFYING';
const defaultMinLapTime = 3; // In seconds

/// How long to show the finish screen
const defaultFinishPageDuration = 60000; // In milliseconds

const defaultRfidToggleable = false;
const defaultUseBarcodesForUsers = false;
const defaultSoundEffects = false;

// Key for the shared preferences / JSON file
const serverUrlKey = 'serverUrl';
const restPortKey = 'restPort';
const websocketPortKey = 'websocketPort';
const circuitNameKey = 'circuitName';
const circuitLengthKey = 'circuitLength';
const practiceLapsKey = 'practiceLaps';
const qualifyingLapsKey = 'qualifyingLaps';
const finishPageDurationKey = 'finishPageDuration';
const eventNameKey = 'eventName';
const raceLapsKey = 'raceLaps';
const raceLightsKey = 'raceLights';
const scannedThingNameKey = 'scannedThingName';
const rfidReaderUrlKey = 'rfidReaderUrl';
const raceModeKey = 'raceMode';
const backgroundImageKey = 'backgroundImage';
const minLapTimeKey = 'minLapTime';
const rfidToggleableKey = 'rfidToggleable';
const useBarcodesForUsersKey = 'useBarcodesForUsers';
const soundEffectsKey = 'soundEffects';
const carImageKey = 'carImage';
const secondCarImageKey = 'secondCarImage';
const trackImageKey = 'trackImage';
const brandImageKey = 'brandImage';
