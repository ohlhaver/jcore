require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe JCore::Extracter do
  
  describe 'applying learned template to same page' do
    
    before do
      document = File.open(File.dirname(__FILE__) + '/data/labeled/story_001.html').read
      template = JCore::Template.new([:author, :summary, :text], :ft, 7)
      template = JCore::Learner.learn(document, template)
      document = File.open(File.dirname(__FILE__) + '/data/unlabeled/story_001.html').read
      @information = JCore::Extracter.extract(document, template)
    end
    
    it 'should extract author string' do
      @information[:author].should == "By Tim Johnston in Bangkok"
    end
    
    it 'should extract summary string' do
      @information[:summary].should == "The decision by the generals who run Burma to <a>extend Aung San Suu Kyi’s incarceration</a> by a further 18 months has snuffed out the dim hope that the regime is becoming more sensitive to international pressure for democratic reforms."
    end
    
    it 'should extract first text string' do
      @information[:text].should be_include(%q(Tuesday’s verdict was widely expected: governments and international rights organisations released prepared condemnations only minutes after it was announced.</p><p>But it has provided a stark illustration of the west’s inability both to change the direction of the Burmese government and the paucity of its arsenal when it comes to punishing regimes that fail to bend to its will.</p><p>In her closing statement, Ms Suu Kyi said that such a verdict would condemn the authorities as much as her companions and herself.</p><p>“The court will pronounce on the innocence or guilt of a few individuals. The verdict itself will constitute a judgment on the whole of the law, justice and constitutionalism in our country,” she said.))
    end
    
    it 'should extract second text string' do
      @information[:text].should be_include(%q(Before Ms Suu Kyi’s arrest, there was growing international support for the idea that sanctions had failed to persuade the generals to improve democratic freedom or human rights, and that some form of diplomatic and commercial re-engagement might be more effective.</p><p>However, Tuesday’s verdict will give new ammunition to the pro-sanctions lobby, making it harder for governments to explore a more nuanced approach.</p><p>At the same time, it is going to be hard for the international community to toughen its stance.</p><p>“If you look at economic sanctions, our leverage is minimal. There is nothing exciting in our back pocket,” said one European diplomat, speaking on condition of anonymity.</p><p>China and Russia, which have vetoes in the United Nations Security Council, have previously protected Burma from western moves to impose internationally binding sanctions.</p><p>On Wednesday, the Chinese Foreign Ministry asked the global community to respect Burma’s judicial sovereignty, a sign that Beijing would not back a proposal for the United Nations Security Council to adopt a statement condemning the sentence.</p><p>Although next year’s elections in Burma are now the focus of attention, the administration of US president barack Obama does not yet have a formal policy on Burma. In February, Hillary Clinton, the US secretary of state, said neither long-standing US sanctions nor attempts to engage Burma diplomatically had worked. </p><p>Analysts say the generals were determined to use the court case to keep Ms Suu Kyi – still their most formidable opponent  – out of circulation ahead of elections, notwithstanding the fact that the constitution written by the regime guarantees the military 25 per cent of the seats in the new parliament.</p><p>“She is not being imprisoned because an American swam to her home but because she is viewed as a strong threat to the legitimacy of this regime and its plans for next year’s elections,” said Jared Genser, a lawyer who represents Ms Suu Kyi overseas.</p><p>Ms Suu Kyi’s supporters in the National League for Democracy say that while her freedom would be vital for a free and fair ballot, it would not be enough in itself. They argue that even if she was freed, the constitution still gives the military an unfair advantage.</p><p>The fact that the international community has used every measure and threat and still failed to influence the outcome of this trial gives little hope to those who are looking for overseas pressure to try and get the constitution amended.</p><p>The visit by John Yettaw in May to Ms Suu Kyi’s place of house arrest offered the military regime an opportunity not just to keep her out of the electoral equation, but also to undermine her status as possibly the world’s most famous prisoner of conscience by trying her on criminal charges in courts that have long done the government’s bidding.</p><p>The international reaction was instant after the news broke of Ms Suu Kyi’s impending trial on criminal charges. Mr Obama called the charges spurious and said she should be released. European powers threatened to widen their sanctions against the regime. Even China, one of the regime’s few remaining allies, signed a statement calling on Burma to release political prisoners.</p><p>The Burmese authorities responded by ensuring the case had all the trimmings of due legal process: it had judges, defence attorneys and a system of appeal, although the judges barred some defence witnesses.</p><p>The defence argued that Ms Suu Kyi had neither invited nor welcomed the intrusion, and pointed out that the law under which she was being charged was part of a constitution that the generals themselves had repealed.))
    end
    
  end
  
  describe 'applying learned template to new page' do
    
    before do
      document = File.open(File.dirname(__FILE__) + '/data/labeled/story_001.html').read
      template = JCore::Template.new([:author, :summary, :text], :ft, 20)
      template = JCore::Learner.learn(document, template)
      document = File.open(File.dirname(__FILE__) + '/data/unlabeled/story_002.html').read
      @information = JCore::Extracter.extract(document, template)
    end
    
    it 'should extract author string' do
      @information[:author].should == "By Peter Smith in Sydney"
    end
    
    it 'should extract summary string' do
      @information[:summary].should == "The Australian government’s ambitious carbon trading scheme legislation was overwhelmingly defeated in the country’s upper house Senate on Thursday, a move that could lead the ruling Labor party to call an early election.</p><p>Australia had planned to introduce its CTS in mid-2011 and had set a mandatory cut in carbon emissions of 5 per cent by 2020 compared with 2000 levels. It also set a highly conditional upper limit of a 25 per cent cut in the unlikely event there was international agreement on aggressive emission cuts at the Copenhagen climate change conference in December."
    end
    
    it 'should extract first text string' do
      #@information[:text].should be_include(%q(Tuesday’s verdict was widely expected: governments and international rights organisations released prepared condemnations only minutes after it was announced.</p><p>But it has provided a stark illustration of the west’s inability both to change the direction of the Burmese government and the paucity of its arsenal when it comes to punishing regimes that fail to bend to its will.</p><p>In her closing statement, Ms Suu Kyi said that such a verdict would condemn the authorities as much as her companions and herself.</p><p>“The court will pronounce on the innocence or guilt of a few individuals. The verdict itself will constitute a judgment on the whole of the law, justice and constitutionalism in our country,” she said.))
    end
    
    it 'should extract second text string' do
      #@information[:text].should be_include(%q(Before Ms Suu Kyi’s arrest, there was growing international support for the idea that sanctions had failed to persuade the generals to improve democratic freedom or human rights, and that some form of diplomatic and commercial re-engagement might be more effective.</p><p>However, Tuesday’s verdict will give new ammunition to the pro-sanctions lobby, making it harder for governments to explore a more nuanced approach.</p><p>At the same time, it is going to be hard for the international community to toughen its stance.</p><p>“If you look at economic sanctions, our leverage is minimal. There is nothing exciting in our back pocket,” said one European diplomat, speaking on condition of anonymity.</p><p>China and Russia, which have vetoes in the United Nations Security Council, have previously protected Burma from western moves to impose internationally binding sanctions.</p><p>On Wednesday, the Chinese Foreign Ministry asked the global community to respect Burma’s judicial sovereignty, a sign that Beijing would not back a proposal for the United Nations Security Council to adopt a statement condemning the sentence.</p><p>Although next year’s elections in Burma are now the focus of attention, the administration of US president barack Obama does not yet have a formal policy on Burma. In February, Hillary Clinton, the US secretary of state, said neither long-standing US sanctions nor attempts to engage Burma diplomatically had worked. </p><p>Analysts say the generals were determined to use the court case to keep Ms Suu Kyi – still their most formidable opponent  – out of circulation ahead of elections, notwithstanding the fact that the constitution written by the regime guarantees the military 25 per cent of the seats in the new parliament.</p><p>“She is not being imprisoned because an American swam to her home but because she is viewed as a strong threat to the legitimacy of this regime and its plans for next year’s elections,” said Jared Genser, a lawyer who represents Ms Suu Kyi overseas.</p><p>Ms Suu Kyi’s supporters in the National League for Democracy say that while her freedom would be vital for a free and fair ballot, it would not be enough in itself. They argue that even if she was freed, the constitution still gives the military an unfair advantage.</p><p>The fact that the international community has used every measure and threat and still failed to influence the outcome of this trial gives little hope to those who are looking for overseas pressure to try and get the constitution amended.</p><p>The visit by John Yettaw in May to Ms Suu Kyi’s place of house arrest offered the military regime an opportunity not just to keep her out of the electoral equation, but also to undermine her status as possibly the world’s most famous prisoner of conscience by trying her on criminal charges in courts that have long done the government’s bidding.</p><p>The international reaction was instant after the news broke of Ms Suu Kyi’s impending trial on criminal charges. Mr Obama called the charges spurious and said she should be released. European powers threatened to widen their sanctions against the regime. Even China, one of the regime’s few remaining allies, signed a statement calling on Burma to release political prisoners.</p><p>The Burmese authorities responded by ensuring the case had all the trimmings of due legal process: it had judges, defence attorneys and a system of appeal, although the judges barred some defence witnesses.</p><p>The defence argued that Ms Suu Kyi had neither invited nor welcomed the intrusion, and pointed out that the law under which she was being charged was part of a constitution that the generals themselves had repealed.))
    end
    
  end

end