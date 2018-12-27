pragma solidity ^0.4.22;

contract Insurance {
    // represent the identity of a address
    enum Type {unknow, hospital, person}

    struct Account {
        Type _type;
    }

    // a bill insured
    struct Bill {
        uint value;
        bool state;
    }

    // The one who can create a insurance
    address public insurance_institution;
    uint public price;
    uint public percentage;
 
    mapping(address => Account) public accounts;
    mapping(address => mapping(address => Bill)) public bills;

    modifier onlyHospital(address to) {
        require(
            accounts[to]._type == Type.hospital,
            "Only the hospital in this insurance can be included in."
        );
        _;
    }

    modifier onlyPerson(address to) {
        require(
            accounts[to]._type == Type.person,
            "Only insured person can be included in."
        );
        _;
    }

    modifier onlyInsurance() {
        require(
            msg.sender == insurance_institution, 
            "Only the insurance institution can do it."
        );
        _;
    }

    modifier legalPercentage(uint per) {
        require(
            per >= 0 && per <= 100, 
            "The compensation percentage should in [0,100]%."
        );
        _;
    }


    // The insurance institution initiates a insurance contract. 
    constructor(uint pri, uint per) public legalPercentage(per){
        insurance_institution = msg.sender;
        price = pri;
        percentage = per;
    }

    // Get the price for person to buy the insurance.
    function getPrice() public view returns (uint){
        return price;
    }

    // Modify the price for person to buy the insurance.
    function setPrice(uint pri) public onlyInsurance{
        price = pri;
    }

    // Get the compensation percentage.
    function getPercentage() public view returns (uint){
        return percentage;
    }

    // Modify the compensation percentage.
    function setPercentage(uint per) public legalPercentage(per) onlyInsurance{
        percentage = per;
    }

    // Add a hospital to the insurance.
    function addHospital() public {
        require(
            accounts[msg.sender]._type == Type.unknow,
            "You have participated in it."
        );
        accounts[msg.sender]._type = Type.hospital;
    }

    // Add a person to the insurance.
    function addPerson() public payable{
        require(
            accounts[msg.sender]._type == Type.unknow,
            "You have participated in it."
        );
        require(
            msg.value == price,
            "You should pay for the insurance."
        );
        accounts[msg.sender]._type = Type.person;
    }

    // The hospital make out the bill.
    function giveBill(address to, uint value) public onlyHospital(msg.sender) onlyPerson(to){
        require(
            bills[msg.sender][to].value == 0,
            "The bill has existed."
        );
        bills[msg.sender][to].value = value;
        bills[msg.sender][to].state = false;
    }

    // The patient check his bill.
    function checkFee(address to) public view returns (uint){
        require(
            bills[to][msg.sender].value != 0,
            "You do not have any bill insured."
        );
        return bills[to][msg.sender].value;
    }

    // The patient pay for the bill.
    function pay(address to) public payable {
        require(
            bills[to][msg.sender].value != 0,
            "You do not have any bill insured."
        );
        require(
            bills[to][msg.sender].value == msg.value,
            "Please check the amount of your bill."
        );
        to.transfer(msg.value);
        bills[to][msg.sender].state = true;
    }

    // The hospital check the paid bill and agree the refund.
    function refund(address to) public {
        require(
            bills[msg.sender][to].value != 0,
            "The bill does not exist."
        );
        require(
            bills[msg.sender][to].state == true,
            "The patient have not paid for it."
        );
        require(
            address(this).balance >= bills[msg.sender][to].value*percentage/100,
            "The insurance institution goes broke."
        );
        to.transfer(bills[msg.sender][to].value*percentage/100);
        bills[msg.sender][to].value = 0;
        bills[msg.sender][to].state = false;
    }

    function killself() public {
        if (insurance_institution == msg.sender) { 
            selfdestruct(insurance_institution);
        }
    }
    
}