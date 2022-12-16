# Delivery PoP Automation

This Repository has been created to further promote stability with PoPlite.

PoPLite is used as a gate that generates clean PoP Workflow Runs.

## Tasks in delivery-pop-automation:

Both tasks `create-pop-release` and `create-pop-release-candidate` have been created to prevent the following issues: 
1) Not being able to read versions from the master branch due to the qualified branch not being successful L->R in a previous environment. 
2) Pipelines not being versioned. Active PoP development will impact service OnDemand.

Hence, the `pop-release-candidate` branches for all repos used in the workflow can be used to test the latest PoPlite branches. 
Once this has been successful, the repos can be force pushed to a new branch titled `pop-stable`.




