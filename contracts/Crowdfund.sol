// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin's SafeMath Implementation
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Crowdfund is Ownable {
  // SafeMath for safe integer operations
  using SafeMath for uint256;

  // List of all the projects
  Project[] private projects;

  // event for when new project starts
  event ProjectStarted(
    address contractAddress,
    address projectCreator,
    string title,
    string description,
    string imageLink,
    uint256 fundRaisingDeadline, // in unix epoch seconds
    uint256 goalAmount
  );

  function startProject(
    string calldata title,
    string calldata description,
    string calldata imageLink,
    uint durationInDays,
    uint amountToRaise
  ) external onlyOwner {
    // solhint-disable-next-line not-rely-on-time
    uint raiseUntil = block.timestamp.add(durationInDays.mul(1 days));

    Project newProject = new Project(payable(msg.sender), title, description, imageLink, raiseUntil, amountToRaise);
    projects.push(newProject);

    emit ProjectStarted(
      address(newProject),
      msg.sender,
      title,
      description,
      imageLink,
      raiseUntil,
      amountToRaise
    );
  }

  function returnProjects() external view returns(Project[] memory) {
    return projects;
  }

}

contract Project is Ownable {
  using SafeMath for uint256;

  enum ProjectState {
    Fundraising,
    Expired,
    Successful
  }

  // Initialize public variables
  address payable public creator;
  uint public goalAmount;
  uint public completeAt;
  uint256 public currentBalance;
  uint public raisingDeadline;
  string public title;
  string public description;
  string public imageLink;

  // Initialize state at fundraising
  ProjectState public state = ProjectState.Fundraising;

  mapping (address => uint) public contributions;

  // Event when funding is received
  event ReceivedFunding(address contributor, uint amount, uint currentTotal);

  // Event for when the project creator has received their funds
  event CreatorPaid(address recipient);

  modifier theState(ProjectState _state) {
    require(state == _state);
   _;
  }

  constructor
  (
    address payable projectCreator,
    string memory projectTitle,
    string memory projectDescription,
    string memory projectImageLink,
    uint fundRaisingDeadline,
    uint projectGoalAmount
  ) {
    creator = projectCreator;
    title = projectTitle;
    description = projectDescription;
    imageLink = projectImageLink;
    goalAmount = projectGoalAmount;
    raisingDeadline = fundRaisingDeadline;
    currentBalance = 0;
  }

  // Fund a project
  function contribute() external theState(ProjectState.Fundraising) payable {
    // require(msg.sender != creator);

    contributions[msg.sender] = contributions[msg.sender].add(msg.value);
    currentBalance = currentBalance.add(msg.value);
    emit ReceivedFunding(msg.sender, msg.value, currentBalance);

    checkIfFundingExpired();
  }

  // check project state
  function checkIfFundingExpired() public {
    // solhint-disable-next-line not-rely-on-time
    if (block.timestamp > raisingDeadline) {
      state = ProjectState.Expired;
    }
  }

  bool private locked = false;
  function payOut() external onlyOwner returns (bool result) {
    require(!locked, "Reentrant call detected!");
    locked = true;

    uint256 totalRaised = currentBalance;
    currentBalance = 0;

    // solhint-disable-next-line avoid-low-level-calls
    (bool sent, bytes memory data) = creator.call{value: totalRaised}("");

    locked = false;
    if (sent) {
      emit CreatorPaid(creator);
      state = ProjectState.Successful;
      return  true;
    } else {
      currentBalance = totalRaised;
      state = ProjectState.Successful;
    }

    return  false;
  }

  function getDetails() public view returns
    (
      address payable projectCreator,
      string memory projectTitle,
      string memory projectDescription,
      string memory projectImageLink,
      uint fundRaisingDeadline,
      ProjectState currentState,
      uint256 projectGoalAmount,
      uint256 currentAmount
    ) {
      projectCreator = creator;
      projectTitle = title;
      projectDescription = description;
      projectImageLink = imageLink;
      fundRaisingDeadline = raisingDeadline;
      currentState = state;
      projectGoalAmount = goalAmount;
      currentAmount = currentBalance;
    }

}