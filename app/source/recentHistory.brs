' This Source Code Form is subject to the terms of the Mozilla Public
' License, v. 2.0. If a copy of the MPL was not distributed with this file,
' You can obtain one at http://mozilla.org/MPL/2.0/.

function createRecentHistory() as integer
    screen = createObject("roGridScreen")
    port = createObject("roMessagePort")
    screen.setMessagePort(port)
    
    screen.SetBreadcrumbText("Home", "Recent History")
    screen.SetupLists(2)
    screen.SetListNames(["Healthy Choices", "Tasty Choices"])

    screen.SetContentList(0, GetLunchMenuOptions_Healthy())    
    screen.SetContentList(1, GetLunchMenuOptions_Tasty())
        
    screen.show()
    
    while (true)
        event = wait(0, port)
        if type(event) = "roGridScreenEvent" then
            if event.isScreenClosed() then
                return -1
            endif
        endif
    end while
end function

function GetLunchMenuOptions_Healthy() as object
        options = [
            { Title: "Fruit"
              Description: "A Variety of Fresh Fruit"
              HDPosterUrl:"pkg://images/fruit.jpg"
              SDPosterUrl:"pkg://images/fruit.jpg"
            }
            { Title: "Salad"
              Description: "Straight from Local Growers"
              HDPosterUrl:"pkg://images/salad.jpg",
              SDPosterUrl:"pkg://images/salad.jpg",
            }            
            { Title: "Yogurt"
              Description: "Always a Good Choice"
              HDPosterUrl:"pkg://images/yogurt.jpg",
              SDPosterUrl:"pkg://images/yogurt.jpg",
            }
            { Title: "Smoothies"
              Description: "In a Variety of Great Fruit Flavors"
              HDPosterUrl:"pkg://images/smoothie.jpg",
              SDPosterUrl:"pkg://images/smoothie.jpg",
            }
            { Title: "Celery Sticks"
              Description: "A Desperate Last Resort"
              HDPosterUrl:"pkg://images/celery.jpg",
              SDPosterUrl:"pkg://images/celery.jpg",
            }
       ]
       return options
end function

function GetLunchMenuOptions_Tasty() as object
        options = [
            { Title: "American"
              Description: "The Classic Burger"
              HDPosterUrl:"pkg://images/burger.jpg"
              SDPosterUrl:"pkg://images/burger.jpg"
            }
            { Title: "Chinese"
              Description: "Served with plenty of MSG"
              HDPosterUrl:"pkg://images/chinese.jpg",
              SDPosterUrl:"pkg://images/chinese.jpg",
            }            
            { Title: "Japanese"
              Description: "We have lots of sushi"
              HDPosterUrl:"pkg://images/sushi.jpg",
              SDPosterUrl:"pkg://images/sushi.jpg",
            }
            { Title: "Mexican"
              Description: "Great Burritos"
              HDPosterUrl:"pkg://images/mexican.jpg",
              SDPosterUrl:"pkg://images/mexican.jpg",
            }
            { Title: "Indian"
              Description: "Curries and More"
              HDPosterUrl:"pkg://images/indian.jpg",
              SDPosterUrl:"pkg://images/indian.jpg",
            }
       ]
       return options
end function