Class LoginException : System.Exception {
    LoginException([String] $Message) : base($Message) {}
}

Class CsvReadException : System.Exception {
    CsvReadException([String] $Message) : base($Message) {}
}

Class DestinationException : System.Exception {
    DestinationException([String] $Message) : base($Message) {}
}

Class UriLoadException : System.Exception {
    UriLoadException([String] $Message) : base($Message) {}
}
