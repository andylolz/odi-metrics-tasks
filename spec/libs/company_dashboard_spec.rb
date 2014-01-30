require 'spec_helper'

describe CompanyDashboard do

  it "should store right values in metrics API", :vcr do
    Timecop.freeze
    time = DateTime.now
    metrics_api_should_receive("current-year-reach", time, 775655)
    metrics_api_should_receive("cumulative-reach", time, 1079051)
    metrics_api_should_receive("current-year-bookings", time, 0)
    metrics_api_should_receive("cumulative-bookings", time, 2191064)
    metrics_api_should_receive("current-year-value-unlocked", time, 0)
    metrics_api_should_receive("cumulative-value-unlocked", time, 16924307)
    metrics_api_should_receive("current-year-commercial-bookings", time, '{"actual": 78.0,"target": 874.48}')
    metrics_api_should_receive("current-year-non-commercial-bookings", time, '{"actual": 156.0,"target": 45.2}')
    metrics_api_should_receive("current-year-kpi-performance", time, 1.0)
    metrics_api_should_receive("current-year-grant-funding", time, '{"actual": 3040.00,"target": 3354.6176046176}')
    metrics_api_should_receive("current-year-income-by-type", time, '{"research": 900.00,"training": 289.00,"projects": 900.00,"network": 912.00}')
    metrics_api_should_receive("current-year-income-by-sector", time, '{"actual": 890.00,"target": 1500.00}')
    metrics_api_should_receive("current-year-income-by-sector", time, '{"actual": 423.00,"target": 750.00}')
    metrics_api_should_receive("current-year-income-by-sector", time, '{"actual": 87.00,"target": 128.12}')
    metrics_api_should_receive("current-year-income-by-sector", time, '{"actual": 121.00,"target": 180.78}')
    metrics_api_should_receive("current-year-income-by-sector", time, '{"actual": 123.00,"target": 450.00}') 
    metrics_api_should_receive("current-year-income-by-sector", time, '{"actual": 212.00,"target": 500.00}')      
    CompanyDashboard.perform
    Timecop.return
  end

  it "should show the correct reach", :vcr do
    CompanyDashboard.reach(2013).should == 303396
    CompanyDashboard.reach(2014).should == 775655
    CompanyDashboard.reach.should == 1079051
  end

  it "should show the correct bookings value", :vcr do
    CompanyDashboard.bookings(2013).should == 2191064
    CompanyDashboard.bookings(2014).should == 0
    CompanyDashboard.bookings.should == 2191064
  end

  it "should show the correct unlocked value", :vcr do
    CompanyDashboard.value(2013).should == 16924307
    CompanyDashboard.value(2014).should == 0
    CompanyDashboard.value.should == 16924307
  end

  it "should show the correct kpi percentage", :vcr do
    CompanyDashboard.kpis(2013).should == 100.0
    CompanyDashboard.kpis(2014).should == 1.0
  end

  it "should show the correct network size", :vcr do
    CompanyDashboard.network.should == {
        :total     => 0,
        :breakdown => {
            :members    => 0,
            :nodes      => 0,
            :startups   => 0,
            :affiliates => 0
        }
    }
  end
  
  it "should show total commercial bookings", :vcr do
    CompanyDashboard.bookings_by_type("Commercial", 2014).should == {
      actual: 78.0,
      target: 874.48
    }
  end

  it "should show total non-commercial bookings", :vcr do
    CompanyDashboard.bookings_by_type("Non-commercial", 2014).should == {
      actual: 156.0,
      target: 45.2
    }
  end
  
  it "should show total grant funding", :vcr do
    CompanyDashboard.grant_funding(2014).should == {
      actual: 3040.00,
      target: 3354.6176046176
    }
  end

  it "should show total income", :vcr do
    CompanyDashboard.total_income(2014).should == 666
  end
  
  it "should show income by type", :vcr do
    CompanyDashboard.income_by_type(2014).should == {
      research: 900.00,
      training: 289.00,
      projects: 900.00,
      network: 912.00
    }
  end
  
  context "income by sector" do
  
    it "should show commercial income for research", :vcr do
      CompanyDashboard.income_by_sector("Commercial", "research", 2014).should == {
        actual: 890.00,
        target: 1500.00
      }
    end
    
    it "should show non-commercial income for research", :vcr do
      CompanyDashboard.income_by_sector("Non-commercial", "research", 2014).should == {
        actual: 423.00,
        target: 750.00
      }
    end
    
    it "should show commercial income for training", :vcr do
      CompanyDashboard.income_by_sector("Commercial", "training", 2014).should == {
        actual: 87.00,
        target: 128.12
      }
    end
    
    it "should show non-commercial income for training", :vcr do
      CompanyDashboard.income_by_sector("Non-commercial", "training", 2014).should == {
        actual: 121.00,
        target: 180.78
      }
    end

    it "should show commercial income for projects", :vcr do
      CompanyDashboard.income_by_sector("Commercial", "project", 2014).should == {
        actual: 123.00,
        target: 450.00
      }
    end
    
    it "should show non-commercial income for projects", :vcr do
      CompanyDashboard.income_by_sector("Non-commercial", "project", 2014).should == {
        actual: 212.00,
        target: 500.00
      }
    end
  
  end
  
#  it "should show grant funding amounts", :vcr do
#    CompanyDashboard.grant_funding(2014).should == 0
#  end

  after :each do
    CompanyDashboard.clear_cache!
  end

end