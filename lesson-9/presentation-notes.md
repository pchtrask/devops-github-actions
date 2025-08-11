# Lesson 9 Presentation Notes
## Performance Testing with JMeter in GitHub Actions

### Slide 1: Introduction & Motivation
**Title**: "Why Performance Testing in CI/CD?"

**Key Points to Cover**:
- Show statistics: 40% of users abandon sites that take >3 seconds to load
- Explain the cost of finding performance issues in production vs development
- Demonstrate the shift-left approach for performance testing

**Visual Suggestions**:
- Timeline showing cost increase from dev → test → prod
- Before/after comparison of manual vs automated performance testing

**Speaker Notes**:
"Today we're adding a critical piece to our DevOps pipeline - automated performance testing. This isn't just about checking if our app works, but how well it performs under load."

---

### Slide 2: GitHub Actions Workflow Architecture
**Title**: "Building the Performance Testing Stage"

**Key Points to Cover**:
- Show the pipeline flow: Build → Test → Performance Test → Deploy
- Explain why we need Java for JMeter
- Discuss environment isolation for testing

**Visual Suggestions**:
- Pipeline diagram with performance testing highlighted
- Code snippet with syntax highlighting
- Architecture diagram showing runner → JMeter → target URL

**Speaker Notes**:
"We're adding this as a separate stage that can run independently. Notice we're using the 'dev' environment - this gives us control over when and where these tests run."

---

### Slide 3: JMeter Installation Strategy
**Title**: "Automated Tool Setup in CI/CD"

**Key Points to Cover**:
- Why we download directly vs using package managers
- Importance of version pinning
- System-wide installation benefits

**Visual Suggestions**:
- Step-by-step installation flow diagram
- Comparison table: Package manager vs Direct download
- File system structure showing /opt/jmeter

**Speaker Notes**:
"We're being very deliberate about our installation approach. By downloading a specific version, we ensure our tests are reproducible across different runs and environments."

---

### Slide 4: Test Plan Deep Dive
**Title**: "Designing Realistic Performance Tests"

**Key Points to Cover**:
- Thread group configuration and why these numbers matter
- Importance of realistic user simulation
- Assertion strategy for quality gates

**Visual Suggestions**:
- JMeter GUI screenshot showing the test plan structure
- Graph showing load pattern over 60 seconds
- Timeline showing ramp-up, steady state, and ramp-down

**Speaker Notes**:
"Our test simulates 5 users over 60 seconds - this might seem small, but it's about establishing baselines and catching regressions, not stress testing in CI."

---

### Slide 5: Results and Continuous Improvement
**Title**: "From Data to Insights"

**Key Points to Cover**:
- What the HTML reports show you
- How to use artifacts for trend analysis
- Setting up performance gates for the future

**Visual Suggestions**:
- Screenshot of JMeter HTML report dashboard
- Trend graph showing performance over multiple builds
- Example of a failed build due to performance regression

**Speaker Notes**:
"The real value comes from tracking these metrics over time. You can see when a code change impacts performance and catch issues before they reach users."

---

## Additional Teaching Tips

### Demo Suggestions:
1. **Live Demo**: Run the local test script during class
2. **Show Real Results**: Display actual JMeter HTML reports
3. **GitHub Actions**: Walk through the Actions tab showing a completed run

### Common Questions & Answers:
- **Q**: "Why only 5 users?"
  **A**: "CI/CD performance tests are about regression detection, not capacity planning. We want fast, consistent feedback."

- **Q**: "What if the test fails?"
  **A**: "That's the point! A failing performance test should block deployment just like a failing unit test."

- **Q**: "How do we test different environments?"
  **A**: "We use the TEST_URL variable - different environments can have different URLs configured."

### Hands-on Exercise:
Have students:
1. Fork the repository
2. Set up their own TEST_URL variable
3. Run the lesson9 workflow
4. Download and examine the results

### Assessment Ideas:
- Modify the test to run for 30 seconds instead of 60
- Add a second HTTP request to the test plan
- Configure the test to fail if response time > 2 seconds
