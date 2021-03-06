pragma solidity 0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ServiceProvider.sol";
import "../contracts/FilmRentalService.sol";

/**
 * Unit tests for the trial subscription functionality in the ServiceProvider contract
 * with only 1 service is being subscribed to.
 */
contract SubscribeToOneServiceTrialTest {

    ServiceProvider private serviceProvider;
    string constant private film = "www.getMyFilm.com/logan";
    string private filmRentalServiceName;

    uint public initialBalance = 10 ether;

    function beforeEachTest() public {
        address a = DeployedAddresses.FilmRentalService();
        filmRentalServiceName = Service(a).getServiceName();
        address[] memory addresses = new address[](1);
        addresses[0] =a;
        serviceProvider = new ServiceProvider(addresses);
    }

    function testOwner() public {
        Assert.equal(serviceProvider.owner(), this, "Owner should be the deployer");
    }

    //Cycle a user through the different stages of subscription i.e.
    //Not subscribed
    //subscribed
    //expired
    //and make sure that the getSubscriptionStatus function returns the correct subscription status each time
    function testGetSubscriptionStatus() public {
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==2,true,"Service thinks a non-subscribed user has subscribed");
        serviceProvider.subscribeToTrial(filmRentalServiceName);
	      Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==0,true,"Service thinks a subscribed user has not subscribed");
        serviceProvider.setDay(2);
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==1,true,"Service is not picking up the fact that a user has expired");
        //Move on one more day and make sure they're still expired
        serviceProvider.setDay(3);
        Assert.equal(serviceProvider.getSubscriptionStatus(filmRentalServiceName)==1,true,"Service is not picking up the fact that a user has expired");
    }

    //Check that the subscribeToTrial function returns true only for new users i.e. not for ones that have already subscribed or that have expired subscriptions
    function testSubscribeToTrial() public {
        Assert.equal(serviceProvider.subscribeToTrial(filmRentalServiceName), true, "Subscription failed for new user");
        Assert.equal(serviceProvider.subscribeToTrial(filmRentalServiceName), false, "Subscription succeeded for user who is already subscribed and active");
        serviceProvider.setDay(2);
        Assert.equal(serviceProvider.subscribeToTrial(filmRentalServiceName), false, "Subscription succeeded for user who is already subscribed and expired");
    }

    //Make sure the service being provided functions correctly when used and that only users who have valid subscriptions can use it
    function testUseService() public {
        string memory result =  serviceProvider.callService(filmRentalServiceName);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is not subscribed and tries to use the service");
        serviceProvider.subscribeToTrial(filmRentalServiceName);
        result = serviceProvider.callService(filmRentalServiceName);
        Assert.equal(result,film,"Wrong film");
        serviceProvider.setDay(2);
        result =  serviceProvider.callService(filmRentalServiceName);
        Assert.equal(result,serviceProvider.notsubscribed(),"Service doesn't provide 'not subscribed' message for when a user is expired and tries to use the service");
    }
}
