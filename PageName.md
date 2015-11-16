# ScadaScan #

Audit SCADA network for Vulnerabilities

# Introduction #

ScadaScan finds SCADA slaves in the network. The tool works on the IP range that is provided on command line and currently supports enumeration of DNP 3 and Modbus slaves. In the Modbus mode the tool bruteforces the first unit ID (or slave ID) by sending ‘Modbus Read Register’ message. In the DNP mode the tool sends a DNP ‘Request Link Status’ message to DNP slaves. The tool can be used to map Modbus and DNP 3 slaves in scada network. The next release of ScadaScan will support scanning of SCADA Master and will have vulnerability detection capabilities for multiple SCADA Master Systems.