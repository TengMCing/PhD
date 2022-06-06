result <- allocate_result %>%
  left_join(lineup, by = c("lineup_id"))

result %>%
  filter(subject %in% 1:20) %>%
  ggplot() +
  geom_jitter(aes(factor(a),
                 factor(e_sigma),
                 shape = x_dist,
                 col = factor(n)),
             width = 0,
             height = 0.2,
             size = 3) +
  facet_wrap(~subject) +
  theme_bw()
